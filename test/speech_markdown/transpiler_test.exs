defmodule SpeechMarkdown.TranspilerTest do
  use ExUnit.Case, async: true

  import SpeechMarkdown.Transpiler

  describe "deduce_tags" do
    setup do
      {:ok, %{spec: get_spec(:general)}}
    end

    test "sub", %{spec: spec} do
      assert {:ok, {:sub, [alias: 'Lalala'], ['ll']}} =
               deduce_tags(spec, [sub: "Lalala"], "ll")
    end

    test "lang", %{spec: spec} do
      assert {:ok, {:lang, ["xml:lang": 'NL'], ['Bonjour']}} =
               deduce_tags(spec, [lang: "NL"], "Bonjour")
    end

    test "combined", %{spec: spec} do
      assert {:ok, {:lang, ["xml:lang": 'NL'], [{:sub, [alias: 'x'], ['y']}]}} =
               deduce_tags(spec, [lang: "NL", sub: "x"], "y")
    end
  end
end
