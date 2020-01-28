defmodule SpeechMarkdown.Validator do
  @blocks ~w(address cardinal number characters expletive bleep fraction interjection ordinal phone telephone unit whisper emphasis excited disappointed)
  @attributes ~w(break date emphasis lang voice pitch ipa sub disappointed excited)

  @enum_attrs [
    rate: ~w(x-slow slow medium fast x-fast),
    volume: ~w(silent x-soft soft medium loud x-loud),
    emphasis: ~w(strong moderate none reduced),
    pitch: ~w(x-low low medium high x-high)
  ]

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

  defp validate_node({:nested_block, nodes, node}) do
    with {:ok, node} <- convert_nested(node),
         {:ok, new_nodes} <- validate(nodes) do
      {:ok, {:nested_block, new_nodes, node}}
    end
  end

  defp validate_node({:block, <<x, _::binary>> = break})
       when x >= ?0 and x <= ?9 do
    # validate break
    with :ok <- valid_delay(break) do
      {:ok, {:kv_block, [{"break", break}]}}
    end
  end

  defp validate_node({:block, block}) do
    {:error, {:invalid_toplevel_block, block}}
  end

  defp validate_node({:kv_block, kvs}) do
    with {:ok, kvs1} <- validate_kvs(kvs) do
      {:ok, {:kv_block, kvs1}}
    end
  end

  defp validate_node({:section, {:kv_block, kvs}}) do
    with {:ok, kvs1} <- validate_kvs(kvs) do
      {:ok, {:section, kvs1}}
    end
  end

  defp validate_node({:section, {:block, "defaults"}}) do
    {:ok, {:section, nil}}
  end

  defp validate_node({:section, {:block, value}}) do
    {:ok, {:section, value}}
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
    defp validate_kvs([{unquote(Atom.to_string(attr)), value} = kv | rest], acc)
         when value in unquote(enum) do
      validate_kvs(rest, [kv | acc])
    end

    defp validate_kvs(
           [{unquote(Atom.to_string(attr)), value} | _rest],
           _acc
         ) do
      {:error,
       {:invalid_attribute_value, {unquote(Atom.to_string(attr)), value}}}
    end
  end

  defp validate_kvs([{"break", break} | rest], acc) do
    with :ok <- valid_delay(break) do
      validate_kvs(rest, [{"break", break} | acc])
    end
  end

  defp validate_kvs([{k, _v} = kv | rest], acc) when k in @attributes do
    validate_kvs(rest, [kv | acc])
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

  defp convert_nested({:block, block}) when block in @blocks do
    {:ok, {:block, block}}
  end

  @translate_blocks %{"chars" => "characters"}
  @translate_block_header Map.keys(@translate_blocks)

  defp convert_nested({:block, block}) when block in @translate_block_header do
    {:ok, {:block, @translate_blocks[block]}}
  end

  defp convert_nested({:block, block}) do
    {:error, {:invalid_block, block}}
  end

  defp convert_nested({:ipa, ipa}) do
    {:ok, {:kv_block, [{"ipa", ipa}]}}
  end

  defp convert_nested({:sub, sub}) do
    {:ok, {:kv_block, [{"sub", sub}]}}
  end

  defp convert_nested({:kv_block, kvs}) do
    with {:ok, kvs1} <- validate_kvs(kvs) do
      {:ok, {:kv_block, kvs1}}
    end
  end

  def break_attr(type) when type in @delay_enum, do: :strength
  def break_attr(_type), do: :time
end
