defmodule SpeechMarkdown.ValidatorTest do
  use ExUnit.Case

  import SpeechMarkdown.Validator
  import SpeechMarkdown.Grammar

  test "validate" do
    assert {:ok, _} = validate_ast([{:text, "hello"}])

    assert {:ok, _} =
             validate_ast([
               {:nested_block, [text: "address"], {:block, "address"}}
             ])
  end

  test "validate breaks" do
    assert {:ok, _} = validate_ast([{:block, "200ms"}])
  end

  test "x" do
    {:ok, ast} =
      parse(
        "hello [200ms] there [lang:\"NL\"] and (foo [300ms] (d)[address] apentuin)[voice:\"James\";lang:\"nl\"] that is it\n\n#[voice:\"x\"] \nxxx"
      )

    IO.inspect(ast, label: "ast")

    assert {:ok, _} = validate_ast(ast)
  end

  test "invalid constructs" do
    assert {:error, _} = validate_ast([{:block, "meh"}])
  end
end
