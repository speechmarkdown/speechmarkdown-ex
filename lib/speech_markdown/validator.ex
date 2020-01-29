defmodule SpeechMarkdown.Validator do
  @moduledoc false

  @attributes ~w(
    address break cardinal characters date disappointed disappointed
    dj emphasis emphasis excited excited expletive fraction
    interjection ipa lang newscaster number ordinal pitch sub
    telephone time unit voice whisper
  )a

  @enum_attrs [
    rate: ~w(x-slow slow medium fast x-fast),
    volume: ~w(silent x-soft soft medium loud x-loud),
    emphasis: ~w(strong moderate none reduced),
    pitch: ~w(x-low low medium high x-high)
  ]

  @delay_re ~r/^(\d+)\s*(ms|sec|day|month|year|y|m|s|h|hour|hours)$/
  @delay_enum ~w(none x-weak weak medium strong x-strong)

  def validate(raw) when is_list(raw) do
    Enum.reduce(
      raw,
      :ok,
      fn
        node, :ok -> validate_node(node)
        _, e -> e
      end
    )
  end

  def break_attr(type) when type in @delay_enum, do: :strength
  def break_attr(_type), do: :time

  ###

  defp validate_node({:text, _}) do
    :ok
  end

  defp validate_node({:audio, _}) do
    :ok
  end

  defp validate_node({:modifier, _text, kvs}) do
    validate_kvs(kvs)
  end

  defp validate_node({:break, break}) do
    valid_delay(break)
  end

  defp validate_node({:section, kvs}) do
    validate_kvs(kvs)
  end

  # defp validate_node({:section, [defaults: nil]}) do
  #   {:ok, {:section, nil}}
  # end

  defp validate_node(node) do
    {:error, {:invalid_node, node}}
  end

  defp validate_kvs({:error, _} = e) do
    e
  end

  defp validate_kvs([]) do
    :ok
  end

  for {attr, enum} <- @enum_attrs do
    defp validate_kvs([{unquote(attr), value} | rest])
         when value in unquote(enum) do
      validate_kvs(rest)
    end

    defp validate_kvs(
           [{unquote(attr), value} | _rest],
           _acc
         ) do
      {:error,
       {:invalid_attribute_value, {unquote(Atom.to_string(attr)), value}}}
    end
  end

  # defp validate_kvs([{:break, break} = n | rest]) do
  #   with :ok <- valid_delay(break) do
  #     validate_kvs(rest, [n | acc])
  #   end
  # end

  defp validate_kvs([{k, _v} | rest]) when k in @attributes do
    validate_kvs(rest)
  end

  defp validate_kvs([{k, _v} | _rest]) do
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
