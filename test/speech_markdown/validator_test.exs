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

  test "validate a large AST" do
    {:ok, ast} =
      parse("""
      hello [200ms] there [lang:"NL"]

      (word)[bleep]

      You say, (pecan)[ipa:"pɪˈkɑːn"].
      I say, (pecan)[/ˈpi.kæn/].

      and (foo [300ms] (d)[address]

      [break:"weak"]
      (lala)[emphasis]
      (lala)[emphasis:"strong"]

      apentuin)[voice:"James";lang:"nl"] that is it\n\n#[voice:"x"] \nxxx

      !["audio.mp3"]

      #[voice:"Kendra";lang:"en-US"]
      Kendra from the US.

      In Paris, they pronounce it (Paris)[lang:"fr-FR"].

      When I wake up, (I speak quite slowly)[rate:"x-slow"].

      """)

    # IO.inspect(ast, label: "ast")

    assert {:ok, _} = validate_ast(ast) |> IO.inspect(label: "i")
  end

  test "invalid constructs" do
    assert {:error, _} = validate_ast([{:block, "meh"}])
  end
end
