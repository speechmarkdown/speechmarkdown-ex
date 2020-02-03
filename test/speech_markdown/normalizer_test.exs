defmodule SpeechMarkdown.NormalizerTest do
  use ExUnit.Case

  import SpeechMarkdown.Grammar

  test "normalize aliases" do
    assert equal("aa", "aa")
    assert equal("(loud)[vol]", "(loud)[volume]")
  end

  test "add defaults" do
    assert parses_to(
             [{:modifier, "loud", [volume: "medium"]}],
             "(loud)[volume]"
           )
  end

  defp parses_to(a, b) do
    assert a === parse!(b)
  end

  defp equal(a, b) do
    assert parse!(a) === parse!(b)
  end
end
