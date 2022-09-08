defmodule SpeechMarkdown.Transpiler do
  @moduledoc false

  alias SpeechMarkdown.{Grammar, Transpiler.Alexa, Validator}

  @doc """
  Transpiles SpeechMarkdown AST into a SSML string.
  """
  @spec transpile(Grammar.t(), SpeechMarkdown.options()) :: {:ok, String.t()}
  def transpile(ast, options) do
    xml_declaration = Keyword.get(options, :xml_declaration, false)
    variant = Keyword.get(options, :variant, :general)

    {:ok,
     [{:speak, Enum.map(ast, &convert(&1, variant))}]
     |> :xmerl.export_simple(:xmerl_xml)
     |> IO.chardata_to_string()
     |> opt_strip_declaration(xml_declaration)}
  end

  defp convert({:break, break}, _variant) do
    {:break, [{Validator.break_attr(break), break}], []}
  end

  defp convert({:modifier, inner, modifier_keys}, variant)
       when is_binary(inner) do
    inner = Enum.map([text: inner], &convert(&1, variant))

    with {:ok, node} <-
           variant |> get_spec() |> deduce_tags(modifier_keys, inner) do
      node
    end
  end

  defp convert({:section, modifier_keys, nodes}, variant) do
    inner = Enum.map(nodes, &convert(&1, variant))

    with {:ok, node} <-
           variant |> get_spec() |> deduce_tags(modifier_keys, inner) do
      node
    end
  end

  defp convert({:audio, src}, _variant) do
    {:audio, [src: src], []}
  end

  defp convert({:mark, name}, _variant) do
    {:mark, [name: name], []}
  end

  defp convert({:text, text}, _variant) do
    ch(String.trim_leading(text, "\n"))
  end

  defp convert(_unknown, _variant) do
    []
  end

  defp opt_strip_declaration("<?xml version=\"1.0\"?>" <> rest, false), do: rest
  defp opt_strip_declaration(input, _false), do: input

  def plaintext(ast) when is_list(ast) do
    output =
      ast
      |> Enum.map(&plaintext_node/1)
      |> IO.chardata_to_string()
      |> String.trim()

    {:ok, Regex.replace(~r/\s+?(\s)/, output, "\\1")}
  end

  defp plaintext_node({:text, text}) do
    text
  end

  defp plaintext_node({:modifier, text, _}) do
    text
  end

  defp plaintext_node(_) do
    []
  end

  defdelegate ch(s), to: Kernel, as: :to_charlist

  defp filter_duplicate_say_as(modifier_keys, spec) do
    modifier_keys
    |> Enum.map(fn {k, v} -> {{k, v}, Enum.find(spec, &(elem(&1, 0) == k))} end)
    |> reduce_duplicate_say_as([])
    |> Enum.reverse()
    |> Enum.map(&elem(&1, 0))
  end

  defp reduce_duplicate_say_as([last], acc) do
    [last | acc]
  end

  defp reduce_duplicate_say_as(
         [{_, {_, :"say-as", _}}, {_, {_, :"say-as", _} = item} | rest],
         acc
       ) do
    reduce_duplicate_say_as([item | rest], acc)
  end

  defp reduce_duplicate_say_as([item | rest], acc) do
    reduce_duplicate_say_as(rest, [item | acc])
  end

  def deduce_tags(spec, modifier_keys, child_node) do
    modifier_keys = filter_duplicate_say_as(modifier_keys, spec)

    result =
      spec
      |> Enum.reverse()
      |> Enum.reduce(child_node, fn
        {key, tag, attr}, child_node ->
          case Keyword.fetch(modifier_keys, key) do
            {:ok, value} ->
              tag =
                {tag, [{attr, ch(value || key)}], as_child_nodes(child_node)}

              tag_postprocess(key, value, tag)

            :error ->
              child_node
          end
      end)
      |> combine_elements(modifier_keys)

    {:ok, result}
  end

  defp as_child_nodes(text) when is_binary(text) do
    [ch(text)]
  end

  defp as_child_nodes({_, _, _} = node) do
    [node]
  end

  defp as_child_nodes(l) when is_list(l) do
    l
  end

  defp combine_elements(
         {:prosody, attrs, [{:prosody, attrs2, children}]},
         ordering
       ) do
    combine_elements({:prosody, attrs ++ attrs2, children}, ordering)
  end

  defp combine_elements(
         {:"say-as", attrs, [{:"say-as", attrs, children}]},
         ordering
       ) do
    combine_elements({:"say-as", attrs, children}, ordering)
  end

  defp combine_elements({tag, attrs, children}, ordering) do
    {tag, attrs, children |> Enum.map(&combine_elements(&1, ordering))}
  end

  defp combine_elements(other, _) do
    other
  end

  @google_unsupported ~w(ipa interjection disappointed excited dj newscaster voice lang)a

  def get_spec(:google) do
    get_spec(:general, [], [{:whisper, :prosody, :google}])
    |> Enum.reject(&(elem(&1, 0) in @google_unsupported))
  end

  def get_spec(:alexa) do
    get_spec(
      :general,
      [
        {:dj, :"amazon:domain", :name},
        {:newscaster, :"amazon:domain", :name},
        {:disappointed, :"amazon:emotion", :name},
        {:excited, :"amazon:emotion", :name}
      ],
      [{:whisper, :"amazon:effect", :name}]
    )
  end

  def get_spec(:general, add_begin \\ [], add_end \\ []) do
    [
      add_begin,
      {:voice, :voice, :name},
      {:lang, :lang, :"xml:lang"},
      {:ipa, :phoneme, :ph},
      {:emphasis, :emphasis, :level},
      {:date, :"say-as", :format},
      {:time, :"say-as", :format},
      {:unit, :"say-as", :"interpret-as"},
      {:address, :"say-as", :"interpret-as"},
      {:characters, :"say-as", :"interpret-as"},
      {:ordinal, :"say-as", :"interpret-as"},
      {:number, :"say-as", :"interpret-as"},
      {:interjection, :"say-as", :"interpret-as"},
      {:expletive, :"say-as", :"interpret-as"},
      {:fraction, :"say-as", :"interpret-as"},
      {:volume, :prosody, :volume},
      {:pitch, :prosody, :pitch},
      {:rate, :prosody, :rate},
      add_end,
      {:sub, :sub, :alias}
    ]
    |> List.flatten()
  end

  defp tag_postprocess(:ipa, _, {t, a, v}) do
    {t, [{:alphabet, 'ipa'} | a], v}
  end

  defp tag_postprocess(date_or_time, _, {t, a, v})
       when date_or_time in ~w(date time)a do
    {t, [{:"interpret-as", ch(date_or_time)} | a], v}
  end

  @intensities ~w(low medium high)
  defp tag_postprocess(emotion, intensity, {tag, _, c})
       when emotion in ~w(disappointed excited)a do
    case String.downcase(intensity) do
      i when i in @intensities ->
        {tag, [name: emotion, intensity: ch(i)], c}

      _ ->
        c
    end
  end

  defp tag_postprocess(:dj, _, {tag, _, c}) do
    {tag, [name: 'music'], c}
  end

  defp tag_postprocess(:newscaster, _, {tag, _, c}) do
    {tag, [name: 'news'], c}
  end

  defp tag_postprocess(:whisper, _, {_, [google: _], c}) do
    {:prosody, [volume: 'x-soft', rate: 'slow'], c}
  end

  defp tag_postprocess(:whisper, _, {tag, _, c}) do
    {tag, [name: 'whispered'], c}
  end

  defp tag_postprocess(:voice, voice, {_tag, _, c}) do
    case Alexa.lookup_voice(voice) do
      nil ->
        c

      voice ->
        {:voice, [name: ch(voice)], c}
    end
  end

  defp tag_postprocess(_key, _value, tag) do
    tag
  end
end
