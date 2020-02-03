defmodule SpeechMarkdown.Normalizer do
  @moduledoc false

  @aliases %{
    vol: :volume,
    bleep: :expletive,
    phone: :telephone,
    chars: :characters
  }
  @alias_keys Map.keys(@aliases)

  @attr_defaults %{
    rate: "medium",
    volume: "medium",
    emphasis: "moderate",
    pitch: "medium",
    excited: "medium",
    disappointed: "medium"
  }

  @doc """
  Normalizes a :block AST tag by adding default values to well-known attributes
  """
  def normalize_block({:block, [break: break]}) do
    {:break, break}
  end

  def normalize_block({:block, kvs}) do
    {:block, normalize_kvs(kvs, [])}
  end

  defp normalize_kvs([], acc) do
    Enum.reverse(acc)
  end

  for {attr, value} <- @attr_defaults do
    defp normalize_kvs([{unquote(attr) = k, nil} | rest], acc) do
      normalize_kvs(rest, [{k, unquote(value)} | acc])
    end
  end

  defp normalize_kvs([{k, v} | rest], acc) when k in @alias_keys do
    normalize_kvs([{@aliases[k], v} | rest], acc)
  end

  defp normalize_kvs([kv | rest], acc) do
    normalize_kvs(rest, [kv | acc])
  end
end
