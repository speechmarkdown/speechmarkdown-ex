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
  @attributes ~w(break date emphasis lang voice ipa)

  defp validate_ast_node({:text, _} = node) do
    {:ok, node}
  end

  defp validate_ast_node({:audio, _} = node) do
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

  defp validate_ast_node({:nested_block, nodes, {:ipa, ipa}}) do
    with {:ok, new_nodes} <- validate_ast(nodes) do
      {:ok, {:nested_block, new_nodes, {:kv_block, [{"ipa", ipa}]}}}
    end
  end

  defp validate_ast_node({:nested_block, nodes, {:kv_block, kvs}}) do
    with :ok <- validate_kvs(kvs), {:ok, new_nodes} <- validate_ast(nodes) do
      {:ok, {:nested_block, new_nodes, {:kv_block, kvs}}}
    end
  end

  defp validate_ast_node({:block, <<x, _::binary>> = break})
       when x >= ?0 and x <= ?9 do
    # validate break
    with :ok <- valid_delay(break) do
      {:ok, {:kv_block, [{:break, break}]}}
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

  @rates ~w(x-slow slow medium fast x-fast)
  defp validate_kvs([{"rate", r} | rest]) do
    case Enum.member?(@rates, r) do
      true ->
        validate_kvs(rest)

      false ->
        {:error, {:invalid_rate, r}}
    end
  end

  @emphasis ~w(strong moderate none reduced)

  defp validate_kvs([{"emphasis", e} | rest]) do
    case Enum.member?(@emphasis, e) do
      true ->
        validate_kvs(rest)

      false ->
        {:error, {:invalid_emphasis, e}}
    end
  end

  defp validate_kvs([{"break", break} | rest]) do
    with :ok <- valid_delay(break) do
      validate_kvs(rest)
    end
  end

  defp validate_kvs([{k, v} | rest]) do
    case Enum.member?(@attributes, k) do
      true -> validate_kvs(rest)
      false -> {:error, {:invalid_attribute, k, v}}
    end
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
end
