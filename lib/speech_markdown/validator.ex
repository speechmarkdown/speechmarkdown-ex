defmodule SpeechMarkdown.Validator do
  def validate_ast(raw) when is_list(raw) do
    with {:ok, nodes} <-
           Enum.reduce(
             raw,
             {:ok, []},
             fn
               node, {:ok, acc} ->
                 with {:ok, n} <- validate_ast_node(node) do
                   {:ok, [n | acc]}
                 end

               _, {:error, e} ->
                 {:error, e}
             end
           ) do
      {:ok, Enum.reverse(nodes)}
    end
  end

  @blocks ~w(address cardinal number characters expletive bleep fraction interjection ordinal phone telephone unit whisper emphasis)
  @attributes ~w(break date emphasis lang voice pitch ipa sub)

  defp validate_ast_node({:text, _} = node) do
    {:ok, node}
  end

  defp validate_ast_node({:audio, _} = node) do
    {:ok, node}
  end

  defp validate_ast_node({:nested_block, nodes, node}) do
    with {:ok, node} <- convert_nested(node),
         {:ok, new_nodes} <- validate_ast(nodes) do
      {:ok, {:nested_block, new_nodes, node}}
    end
  end

  defp validate_ast_node({:block, <<x, _::binary>> = break})
       when x >= ?0 and x <= ?9 do
    # validate break
    with :ok <- valid_delay(break) do
      {:ok, {:kv_block, [{:break, break}]}}
    end
  end

  defp validate_ast_node({:block, block}) do
    {:error, {:invalid_toplevel_block, block}}
  end

  defp validate_ast_node({:kv_block, kvs} = node) do
    with :ok <- validate_kvs(kvs) do
      {:ok, node}
    end
  end

  defp validate_ast_node({:section, {:kv_block, kvs}}) do
    with :ok <- validate_kvs(kvs) do
      {:ok, {:section, kvs}}
    end
  end

  defp validate_ast_node(node) do
    {:error, {:invalid_ast_node, node}}
  end

  defp validate_kvs([]) do
    :ok
  end

  @enum_attrs [
    rate: ~w(x-slow slow medium fast x-fast),
    volume: ~w(silent x-soft soft medium loud x-loud),
    emphasis: ~w(strong moderate none reduced),
    pitch: ~w(x-low low medium high x-high)
  ]

  for {attr, enum} <- @enum_attrs do
    defp validate_kvs([{unquote(Atom.to_string(attr)), value} | rest])
         when value in unquote(enum) do
      validate_kvs(rest)
    end

    defp validate_kvs([{unquote(Atom.to_string(attr)), value} | _rest]) do
      {:error,
       {:invalid_attribute_value, {unquote(Atom.to_string(attr)), value}}}
    end
  end

  defp validate_kvs([{"break", break} | rest]) do
    with :ok <- valid_delay(break) do
      validate_kvs(rest)
    end
  end

  defp validate_kvs([{k, _v} | rest]) when k in @attributes do
    validate_kvs(rest)
  end

  defp validate_kvs([{k, _v} | _rest]) do
    {:error, {:unknown_attribute, k}}
  end

  @delay_re ~r/^(\d+)\s*(ms|sec|day|month|year|y|m|s|h|hour|hours)$/
  @delay_enum ~w(none x-weak weak medium strong x-strong)

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
    with :ok <- validate_kvs(kvs) do
      {:ok, {:kv_block, kvs}}
    end
  end
end
