defmodule SpeechMarkdown.Transpiler do
  @moduledoc """
  The Speech Markdown transpiler converts the markdown text to the
  Speech Synthesis Markup Language (SSML) format. The results are returned
  as an SSML string.
  """

  alias SpeechMarkdown.Grammar

  @doc "convert a markdown string or ast to ssml text"
  @spec transpile!(text :: String.t() | keyword()) :: String.t()
  def transpile!(text) when is_binary(text) do
    text
    |> Grammar.parse!()
    |> transpile!()
  end

  def transpile!(ast) do
    {:ok, xml} = transpile(ast)
    xml
  end

  @doc "convert a markdown string or ast to ssml text"
  @spec transpile(text :: String.t() | keyword()) :: {:ok, String.t()}
  def transpile(text) when is_binary(text) do
    with {:ok, ast} <- Grammar.parse(text) do
      transpile(ast)
    end
  end

  def transpile(ast) do
    {:ok,
     [{:speak, Enum.map(ast, &convert/1)}]
     |> :xmerl.export_simple(:xmerl_xml)
     |> IO.chardata_to_string()}
  end

  defp convert({:break, [time, units]}) do
    {:break, [time: String.to_charlist("#{time}#{units}")], []}
  end

  defp convert({:modifier, [text, ipa: ipa]}) do
    {:phoneme, [alphabet: :ipa, ph: String.to_charlist(ipa)],
     [String.to_charlist(text)]}
  end

  defp convert({:modifier, [text, say: say]}) do
    {:"say-as", ["interpret-as": say], [String.to_charlist(text)]}
  end

  defp convert({:text, text}) do
    String.to_charlist(text)
  end
end
