defmodule SpeechMarkdown.Transpiler do
  @moduledoc """
  The Speech Markdown transpiler converts the markdown text to the
  Speech Synthesis Markup Language (SSML) format. The results are returned
  as an SSML string.
  """

  alias SpeechMarkdown.{Grammar, Validator, Transpiler.Alexa}

  @doc "convert a markdown string or ast to ssml text"
  @spec transpile!([Grammar.node()], SpeechMarkdown.options()) ::
          String.t()
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
    xml_declaration = Keyword.get(options, :xml_declaration, false)
    variant = Keyword.get(options, :variant, :general)

    {:ok,
     [{:speak, Enum.map(ast, &convert(&1, variant))}]
     |> :xmerl.export_simple(:xmerl_xml)
     |> IO.chardata_to_string()
     |> opt_strip_declaration(xml_declaration)}
  end

  ### BREAK

  defp convert({:kv_block, [{"break", break}]}, _variant) do
    {:break, [{Validator.break_attr(break), break}], []}
  end

  ### IPA

  defp convert(
         {:nested_block, nodes, {:kv_block, [{"ipa", _ipa}]}},
         :google
       ) do
    Enum.map(nodes, &convert(&1, :google))
  end

  defp convert(
         {:nested_block, nodes, {:kv_block, [{"ipa", ipa}]}},
         variant
       ) do
    {:phoneme, [alphabet: :ipa, ph: ch(ipa)],
     Enum.map(nodes, &convert(&1, variant))}
  end

  ### SECTIONS

  defp convert({:section, block, nodes}, :alexa) do
    nodes
    |> Enum.map(&convert(&1, :alexa))
    |> Alexa.emotion(block)
  end

  defp convert({:section, _section, inner}, variant) do
    Enum.map(inner, &convert(&1, variant))
  end

  @emotions Alexa.emotions()

  defp convert({:nested_block, nodes, {:block, emotion} = block}, :alexa)
       when emotion in @emotions do
    nodes
    |> Enum.map(&convert(&1, :alexa))
    |> Alexa.emotion(block)
  end

  defp convert(
         {:nested_block, nodes, {:kv_block, [{emotion, _}] = block}},
         :alexa
       )
       when emotion in @emotions do
    nodes
    |> Enum.map(&convert(&1, :alexa))
    |> Alexa.emotion(block)
  end

  defp convert({:nested_block, nodes, {:block, emotion}}, variant)
       when emotion in @emotions do
    Enum.map(nodes, &convert(&1, variant))
  end

  defp convert(
         {:nested_block, nodes, {:kv_block, [{emotion, _}]}},
         variant
       )
       when emotion in @emotions do
    Enum.map(nodes, &convert(&1, variant))
  end

  ### SAY-AS
  defp convert(
         {:nested_block, nodes, {:kv_block, [{"emphasis", level}]}},
         variant
       ) do
    {:emphasis, [level: ch(level)], Enum.map(nodes, &convert(&1, variant))}
  end

  defp convert(
         {:nested_block, nodes, {:kv_block, [{"date", format}]}},
         variant
       ) do
    {:"say-as", ["interpret-as": 'date', format: ch(format)],
     Enum.map(nodes, &convert(&1, variant))}
  end

  @interpret_as ~w(characters number address chars)
  defp convert({:nested_block, nodes, {:block, say}}, variant)
       when say in @interpret_as do
    {:"say-as", ["interpret-as": say], Enum.map(nodes, &convert(&1, variant))}
  end

  defp convert({:audio, src}, _variant) do
    {:audio, [src: ch(src)], []}
  end

  defp convert({:text, text}, _variant) do
    ch(text)
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

  defp plaintext_node({block, _}) when block in ~w(block kv_block audio)a do
    []
  end

  defdelegate ch(s), to: String, as: :to_charlist
end
