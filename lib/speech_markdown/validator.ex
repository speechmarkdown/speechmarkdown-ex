defmodule SpeechMarkdown.Validator do
  @moduledoc false

  @attributes ~w(
    address break cardinal characters date disappointed disappointed
    dj emphasis emphasis excited excited expletive fraction
    interjection ipa lang newscaster number ordinal pitch sub
    telephone time unit voice whisper
  )a

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
    emphasis: "moderate",
    pitch: "medium",
    excited: "medium",
    disappointed: "medium"
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

  def break_attr(type) when type in @delay_enum, do: :strength
  def break_attr(_type), do: :time

  ###

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

  defp validate_node({:block, [break: break]}) do
    with :ok <- valid_delay(break) do
      {:ok, {:break, break}}
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

  for {attr, value} <- @attr_defaults do
    defp validate_kvs([{unquote(attr) = k, nil} | rest], acc) do
      validate_kvs(rest, [{k, unquote(value)} | acc])
    end
  end

  for {attr, enum} <- @enum_attrs do
    defp validate_kvs([{unquote(attr), value} = kv | rest], acc)
         when value in unquote(enum) do
      validate_kvs(rest, [kv | acc])
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
end
