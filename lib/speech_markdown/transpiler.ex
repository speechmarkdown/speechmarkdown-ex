defmodule SpeechMarkdown.Transpiler do
  @moduledoc """
  The Speech Markdown transpiler converts the markdown text to the
  Speech Synthesis Markup Language (SSML) format. The results are returned
  as an SSML string.
  """

  alias SpeechMarkdown.{Grammar, Validator}

  @doc "convert a markdown string or ast to ssml text"
  @spec transpile!(text :: String.t() | keyword(), SpeechMarkdown.options()) ::
          String.t()
  def transpile!(text, options) when is_binary(text) do
    text
    |> Grammar.parse!()
    |> Validator.validate_ast!()
    |> transpile!(options)
  end

  def transpile!(ast, options) do
    {:ok, xml} = transpile(ast, options)
    xml
  end

  @doc "convert a markdown string or ast to ssml text"
  @spec transpile(text :: String.t() | keyword(), SpeechMarkdown.options()) ::
          {:ok, String.t()}
  def transpile(text, options) when is_binary(text) do
    with {:ok, ast} <- Grammar.parse(text) do
      transpile(ast, options)
    end
  end

  def transpile(ast, options) do
    {:ok,
     [{:speak, Enum.map(ast, &convert/1)}]
     |> :xmerl.export_simple(:xmerl_xml)
     |> IO.chardata_to_string()
     |> opt_strip_declaration(Keyword.get(options, :xml_declaration, false))}
  end

  defp convert({:kv_block, [{"break", break}]}) do
    {:break, [time: break], []}
  end

  defp convert({:nested_block, [text: text], {:kv_block, [{"ipa", ipa}]}}) do
    {:phoneme, [alphabet: :ipa, ph: String.to_charlist(ipa)],
     [String.to_charlist(text)]}
  end

  @interpret_as ~w(characters number)
  defp convert({:nested_block, [text: text], {:block, say}})
       when say in @interpret_as do
    {:"say-as", ["interpret-as": say], [String.to_charlist(text)]}
  end

  defp convert({:text, text}) do
    String.to_charlist(text)
  end

  defp opt_strip_declaration("<?xml version=\"1.0\"?>" <> rest, false), do: rest
  defp opt_strip_declaration(input, _false), do: input

  def plaintext(ast) when is_list(ast) do
    output =
      ast
      |> Enum.map(&plaintext_node/1)
      |> IO.chardata_to_string()

    {:ok, Regex.replace(~r/(\s)\s+/, output, "\\1")}
  end

  defp plaintext_node({:text, text}) do
    text
  end

  defp plaintext_node({:nested_block, nodes, _}) do
    nodes |> Enum.map(&plaintext_node/1)
  end

  defp plaintext_node({:block, _}) do
    []
  end
end
