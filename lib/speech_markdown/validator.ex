defmodule SpeechMarkdown.Validator do
  @attributes ~w(break date time emphasis lang voice pitch ipa sub disappointed excited address cardinal number characters expletive fraction interjection ordinal telephone unit whisper emphasis excited disappointed dj newscaster)a

  @aliases %{
    vol: :volume,
    bleep: :expletive,
    phone: :telephone,
    chars: :characters
  }
  @alias_keys Map.keys(@aliases)

  @enum_attrs [
    rate: ~w(x-slow slow medium fast x-fast),
    volume: ~w(silent x-soft soft medium loud x-loud),
    emphasis: ~w(strong moderate none reduced),
    pitch: ~w(x-low low medium high x-high)
  ]

  @attr_defaults %{
    rate: "medium",
    volume: "medium",
    emphasis: "none",
    pitch: "medium"
  }

  @delay_re ~r/^(\d+)\s*(ms|sec|day|month|year|y|m|s|h|hour|hours)$/
  @delay_enum ~w(none x-weak weak medium strong x-strong)

  def validate!(raw) when is_list(raw) do
    {:ok, validated} = validate(raw)
    validated
  end

  def validate(raw) when is_list(raw) do
    with {:ok, nodes} <-
           Enum.reduce(
             raw,
             {:ok, []},
             fn
               node, {:ok, acc} ->
                 with {:ok, n} <- validate_node(node) do
                   {:ok, [n | acc]}
                 end

               _, {:error, e} ->
                 {:error, e}
             end
           ) do
      {:ok, Enum.reverse(nodes)}
    end
  end

  defp validate_node({:text, _} = node) do
    {:ok, node}
  end

  defp validate_node({:audio, _} = node) do
    {:ok, node}
  end

  defp validate_node({:modifier, text, kvs}) do
    with {:ok, kvs} <- validate_kvs(kvs) do
      {:ok, {:modifier, text, kvs}}
    end
  end

  defp validate_node({:block, [break: break]} = node) do
    with :ok <- valid_delay(break) do
      {:ok, node}
    end
  end

  defp validate_node({:block, block}) do
    {:error, {:invalid_toplevel_block, block}}
  end

  defp validate_node({:section, [defaults: nil]}) do
    {:ok, {:section, nil}}
  end

  defp validate_node({:section, kvs}) do
    with {:ok, kvs} <- validate_kvs(kvs) do
      {:ok, {:section, kvs}}
    end
  end

  defp validate_node(node) do
    {:error, {:invalid_node, node}}
  end

  defp validate_kvs(input) do
    validate_kvs(input, [])
    |> case do
      {:error, _} = e -> e
      list -> {:ok, Enum.reverse(list)}
    end
  end

  defp validate_kvs({:error, _} = e, _acc) do
    e
  end

  defp validate_kvs([], acc) do
    acc
  end

  for {attr, enum} <- @enum_attrs do
    defp validate_kvs([{unquote(attr), value} = kv | rest], acc)
         when value in unquote(enum) do
      validate_kvs(rest, [kv | acc])
    end

    defp validate_kvs([{unquote(attr) = k, nil} | rest], acc) do
      validate_kvs(rest, [{k, @attr_defaults[k]} | acc])
    end

    defp validate_kvs(
           [{unquote(attr), value} | _rest],
           _acc
         ) do
      {:error,
       {:invalid_attribute_value, {unquote(Atom.to_string(attr)), value}}}
    end
  end

  defp validate_kvs([{:break, break} = n | rest], acc) do
    with :ok <- valid_delay(break) do
      validate_kvs(rest, [n | acc])
    end
  end

  defp validate_kvs([{k, _v} = kv | rest], acc) when k in @attributes do
    validate_kvs(rest, [kv | acc])
  end

  defp validate_kvs([{k, v} | rest], acc) when k in @alias_keys do
    validate_kvs([{@aliases[k], v} | rest], acc)
  end

  defp validate_kvs([{k, _v} | _rest], _acc) do
    {:error, {:unknown_attribute, k}}
  end

  defp valid_delay(break) when break in @delay_enum do
    :ok
  end

  defp valid_delay(break) do
    case Regex.match?(@delay_re, break) do
      true -> :ok
      false -> {:error, {:invalid_delay, break}}
    end
  end

  def break_attr(type) when type in @delay_enum, do: :strength
  def break_attr(_type), do: :time

  @alexa_voices %{
                  "Ivy" => "en-US",
                  "Joanna" => "en-US",
                  "Joey" => "en-US",
                  "Justin" => "en-US",
                  "Kendra" => "en-US",
                  "Kimberly" => "en-US",
                  "Matthew" => "en-US",
                  "Salli" => "en-US",
                  "Nicole" => "en-AU",
                  "Russell" => "en-AU",
                  "Amy" => "en-GB",
                  "Brian" => "en-GB",
                  "Emma" => "en-GB",
                  "Aditi" => "en-IN",
                  "Raveena" => "en-IN",
                  "Hans" => "de-DE",
                  "Marlene" => "de-DE",
                  "Vicki" => "de-DE",
                  "Conchita" => "es-ES",
                  "Enrique" => "es-ES",
                  "Carla" => "it-IT",
                  "Giorgio" => "it-IT",
                  "Mizuki" => "ja-JP",
                  "Takumi" => "ja-JP",
                  "Celine" => "fr-FR",
                  "Lea" => "fr-FR",
                  "Mathieu" => "fr-FR"
                }
                |> Map.keys()

  def alexa_voice(voice) do
    Enum.find(@alexa_voices, &(String.downcase(&1) == String.downcase(voice)))
  end
end