defmodule SpeechMarkdown.Sectionizer do
  @moduledoc false

  @doc """
  Divides the AST into sections

  Given the AST, get all section nodes and group the following tags
  under the given section.
  """
  def sectionize(ast) do
    Enum.reduce(ast, [{[], []}], &sectionize_node/2)
    |> reverse_last_section()
    |> Enum.reverse()
    |> Enum.map(&flatten_section/1)
    |> List.flatten()
  end

  defp reverse_last_section([{last, last_nodes} | rest]) do
    [{last, Enum.reverse(last_nodes)} | rest]
  end

  defp sectionize_node({:section, contents}, acc) do
    # new section
    [{contents, []} | reverse_last_section(acc)]
  end

  defp sectionize_node(node, [{section, nodes} | rest]) do
    # add to current section
    [{section, [node | nodes]} | rest]
  end

  defp flatten_section({[], nodes}), do: nodes
  defp flatten_section({contents, nodes}), do: {:section, contents, nodes}
end
