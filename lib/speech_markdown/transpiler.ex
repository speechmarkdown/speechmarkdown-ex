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

  ### EMPTY BLOCK
  defp convert({:nested_block, nodes, :empty_block}, variant) do
    Enum.map(nodes, &convert(&1, variant))
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

  defp convert({:section, [{_, _} | _] = attrs, nodes}, :alexa) do
    {alexa_attrs, attrs} =
      Enum.split_with(attrs, &(elem(&1, 0) in ~w(excited disappointed)))

    nodes
    |> Enum.map(&convert(&1, :alexa))
    |> wrap_with_voice_and_or_lang(attrs)
    |> Alexa.emotion(alexa_attrs)
    |> unwrap_single_node()
  end

  defp convert({:section, block, nodes}, :alexa) when is_binary(block) do
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

  ### WHISPER
  defp convert({:nested_block, nodes, {:block, "whisper"}}, :alexa) do
    nodes = Enum.map(nodes, &convert(&1, :alexa))
    {:"amazon:effect", [name: 'whispered'], nodes}
  end

  defp convert({:nested_block, nodes, {:block, "whisper"}}, variant) do
    nodes = Enum.map(nodes, &convert(&1, variant))
    {:prosody, [volume: 'x-soft', rate: 'slow'], nodes}
  end

  ### PROSODY

  defp convert(
         {:nested_block, nodes, {:kv_block, [{"volume", volume}]}},
         variant
       ) do
    {:prosody, [volume: volume], Enum.map(nodes, &convert(&1, variant))}
  end

  defp convert(
         {:nested_block, nodes, {:kv_block, [{"pitch", pitch}]}},
         variant
       ) do
    {:prosody, [pitch: pitch], Enum.map(nodes, &convert(&1, variant))}
  end

  defp convert(
         {:nested_block, nodes, {:kv_block, [{"rate", rate}]}},
         variant
       ) do
    {:prosody, [rate: rate], Enum.map(nodes, &convert(&1, variant))}
  end

  ### LANG

  defp convert({:nested_block, nodes, {:kv_block, [{"lang", _}]}}, :google) do
    Enum.map(nodes, &convert(&1, :google))
  end

  defp convert({:nested_block, nodes, {:kv_block, [{"lang", lang}]}}, variant) do
    {:lang, ["xml:lang": ch(lang)], Enum.map(nodes, &convert(&1, variant))}
  end

  ### SUB

  defp convert({:nested_block, nodes, {:kv_block, [{"sub", sub}]}}, variant) do
    {:sub, [alias: ch(sub)], Enum.map(nodes, &convert(&1, variant))}
  end

  ### VOICE

  defp convert({:nested_block, nodes, {:kv_block, [{"voice", voice}]}}, :alexa) do
    nodes = Enum.map(nodes, &convert(&1, :alexa))

    case Validator.alexa_voice(voice) do
      nil ->
        nodes

      voice ->
        {:voice, [name: ch(voice)], nodes}
    end
  end

  defp convert({:nested_block, nodes, {:kv_block, [{"voice", _}]}}, variant) do
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
         {:nested_block, nodes, {:kv_block, [{dt, format}]}},
         variant
       )
       when dt in ~w(date time) do
    {:"say-as", ["interpret-as": ch(dt), format: ch(format)],
     Enum.map(nodes, &convert(&1, variant))}
  end

  defp convert({:nested_block, nodes, {:block, say}}, :google)
       when say in ~w(interjection) do
    Enum.map(nodes, &convert(&1, :google))
  end

  @interpret_as ~w(characters number address chars expletive fraction interjection ordinal unit)
  defp convert({:nested_block, nodes, {:block, say}}, variant)
       when say in @interpret_as do
    {:"say-as", ["interpret-as": say], Enum.map(nodes, &convert(&1, variant))}
  end

  ### AUDIO

  defp convert({:audio, src}, _variant) do
    {:audio, [src: ch(src)], []}
  end

  ### TEXT

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

  defp wrap_with_voice_and_or_lang(nodes, attrs) do
    ~w(lang voice)
    |> Enum.reduce(nodes, fn
      "lang", children ->
        case kw(attrs, "lang") do
          nil ->
            children

          lang ->
            [{:lang, ["xml:lang": ch(lang)], children}]
        end

      "voice", children ->
        case kw(attrs, "voice") do
          nil ->
            children

          "device" ->
            children

          voice ->
            [{:voice, [name: ch(voice)], children}]
        end
    end)
  end

  defp unwrap_single_node([{_, _, _} = n]), do: n
  defp unwrap_single_node(n), do: n

  defp kw(list, prop) do
    case :proplists.get_value(prop, list) do
      :undefined -> nil
      value -> value
    end
  end
end
