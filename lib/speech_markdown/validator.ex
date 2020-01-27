defmodule SpeechMarkdown.Validator do
  def validate_ast(raw) when is_list(raw) do
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
    )
  end

  @blocks ~w(address cardinal number characters expletive bleep fraction interjection ordinal phone telephone unit whisper)
  @attributes ~w(break date emphasis lang voice)

  defp validate_ast_node({:text, _} = node) do
    {:ok, node}
  end

  # defp validate_ast_node({:block, block} = node) when block in @blocks do
  #   {:ok, node}
  # end

  defp validate_ast_node({:nested_block, nodes, {:block, block}})
       when block in @blocks do
    with {:ok, new_nodes} <- validate_ast(nodes) do
      {:ok, {:nested_block, new_nodes, {:block, block}}}
    end
  end

  defp validate_ast_node({:nested_block, nodes, {:kv_block, kvs}}) do
    with :ok <- validate_kvs(kvs) do
      validate_ast(nodes)
    end
  end

  defp validate_ast_node({:block, <<x, _::binary>> = break})
       when x >= ?0 and x <= ?9 do
    # validate break
    case Regex.run(~r/^(\d+)([a-z]+)/, break) do
      [_, time, unit] ->
        {:ok, {:kv_block, [{:break, {time, unit}}]}}

      _ ->
        {:error, "Invalid time format: " <> break}
    end
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

  defp validate_kvs([{k, v} | rest]) do
    case Enum.member?(@attributes, k) do
      true -> validate_kvs(rest)
      false -> {:error, {:invalid_attribute, k, v}}
    end
  end
end
