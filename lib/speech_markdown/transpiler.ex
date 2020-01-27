defmodule SpeechMarkdown.Transpiler do
  @moduledoc """
  The Speech Markdown transpiler converts the markdown text to the
  Speech Synthesis Markup Language (SSML) format. The results are returned
  as an SSML string.
  """

  alias SpeechMarkdown.Grammar

  @doc "convert a markdown string or ast to ssml text"
  @spec transpile!(text :: String.t() | keyword(), SpeechMarkdown.options()) ::
          String.t()
  def transpile!(text, options) when is_binary(text) do
    text
    |> Grammar.parse!()
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
     |> opt_strip_declaration(Keyword.get(options, :xml_declaration, true))
     |> opt_plaintext_output(Keyword.get(options, :variant, nil))}
  end

  defp convert({:break, [time, units]}) do
    {:break, [time: String.to_charlist("#{time}#{units}")], []}
  end

  defp convert({:modifier, [text, ipa: ipa]}) do
    {:phoneme, [alphabet: :ipa, ph: String.to_charlist(ipa)],
     [String.to_charlist(text)]}
  end

  defp convert({:modifier, [text, say: say]}) do
    {:"say-as", ["interpret-as": say], [String.to_charlist(text)]}
  end

  defp convert({:text, text}) do
    String.to_charlist(text)
  end

  defp opt_strip_declaration("<?xml version=\"1.0\"?>" <> rest, true), do: rest
  defp opt_strip_declaration(input, _false), do: input

  defp opt_plaintext_output(input, :plaintext) do
    Regex.replace(~r/\<[^>]*?>/, input, "")
  end

  defp opt_plaintext_output(input, _), do: input
end
