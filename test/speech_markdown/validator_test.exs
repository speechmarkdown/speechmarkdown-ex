defmodule SpeechMarkdown.ValidatorTest do
  use ExUnit.Case

  import SpeechMarkdown.Validator
  import SpeechMarkdown.Grammar

  test "validate" do
    assert {:ok, _} = validate([{:text, "hello"}])

    assert {:ok, _} =
             validate([
               {:modifier, "address", [{:address, nil}]}
             ])
  end

  test "validate breaks" do
    assert {:ok, _} = validate([{:block, [break: "200ms"]}])
  end

  test "validate a large AST" do
    {:ok, ast} =
      parse("""
      hello [200ms] there (daar)[lang:"NL"]

      I would walk (500 mi)[unit]

      (word)[bleep]

      You say, (pecan)[ipa:"pɪˈkɑːn"].
      I say, (pecan)[/ˈpi.kæn/].

      I can speak with my normal pitch, (but also with a much higher pitch)[pitch:"x-high"].

      (Louder volume for the second sentence)[volume:"x-loud"].


      and foo [300ms] (d)[address]

      [break:"weak"]
      (lala)[emphasis]
      (lala)[emphasis:"strong"]

      apentuin
      #[voice:"James";lang:"nl"]

      that is it\n\n#[voice:"x"] \nxxx

      !["audio.mp3"]

      #[voice:"Kendra";lang:"en-US"]
      Kendra from the US.

      In Paris, they pronounce it (Paris)[lang:"fr-FR"].

      When I wake up, (I speak quite slowly)[rate:"x-slow"].

      My favorite chemical element is (Al)[sub:"aluminum"],
      but Al prefers (Mg)["magnesium"].

      A ++strong++ level
      A +moderate+ level
      A ~none~ level
      A -reduced- level


      """)

    #    IO.inspect(ast, label: "ast")

    assert {:ok, _} = validate(ast)
  end

  test "invalid constructs" do
    assert {:error, _} = validate([{:block, "meh"}])
  end
end
