defmodule SpeechMarkdown.TranspilerTest do
  use ExUnit.Case, async: true

  import SpeechMarkdown.Transpiler

  describe "deduce_tags" do
    setup do
      {:ok, %{spec: get_spec(:general)}}
    end

    test "sub", %{spec: spec} do
      assert {:ok, {:sub, [alias: ~c"Lalala"], [~c"ll"]}} =
               deduce_tags(spec, [sub: "Lalala"], "ll", :general)
    end

    test "lang", %{spec: spec} do
      assert {:ok, {:lang, ["xml:lang": ~c"NL"], [~c"Bonjour"]}} =
               deduce_tags(spec, [lang: "NL"], "Bonjour", :general)
    end

    test "combined", %{spec: spec} do
      assert {:ok,
              {:lang, ["xml:lang": ~c"NL"], [{:sub, [alias: ~c"x"], [~c"y"]}]}} =
               deduce_tags(spec, [lang: "NL", sub: "x"], "y", :general)
    end
  end
end
