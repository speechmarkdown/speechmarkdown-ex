defmodule SpeechMarkdown.Grammar.Test do
  use ExUnit.Case, async: true

  import SpeechMarkdown.Grammar

  test "parse" do
    # # unsupported markup
    assert {:ok, _} = parse("")
    assert {:ok, _} = parse(" ")
    assert {:ok, _} = parse("(")
    assert {:ok, _} = parse(")")
    assert {:ok, _} = parse("[")
    assert {:ok, _} = parse("]")
    assert {:ok, _} = parse("()[]")
    assert {:ok, _} = parse("[invalid]")
    assert {:ok, _} = parse("[break:]")
    assert {:ok, _} = parse("[5m]")
    assert {:ok, _} = parse("(pecan)[ipa:]")
    assert {:ok, _} = parse("(pecan)[/]")
    assert {:ok, _} = parse("(Al)[sub:\"aluminum;\"]")

    # ipa
    assert {:ok, _} = parse("[/pɪˈkɑːn/]")
    assert {:ok, _} = parse("(pecan)[/pɪˈkɑːn/]")

    # # breaks
    assert {:ok, _} = parse("[ 100ms]")
    assert {:ok, _} = parse("[2s ]")
    assert {:ok, _} = parse("[ break : \"5s\" ]")

    # say-as
    assert {:ok, _} = parse("(www)[ characters]")
    assert {:ok, _} = parse("(1234)[number ]")
    assert {:ok, _} = parse("[\"aluminum\"]")
    assert {:ok, _} = parse("(Al)[\"aluminum\"]")

    # audio
    assert {:ok, _} = parse("![\"http://audio.mp3\"]")
    assert {:ok, _} = parse("!()[\"https://audio.mp3\"]")
    assert {:ok, _} = parse("!(hello world)[\"http://audio.mp3\"]")
  end

  test "emphasized symbols" do
    assert [text: "foo - bar - baz"] === parse!("foo - bar - baz")
    assert [text: "foo-bar-baz"] === parse!("foo-bar-baz")

    t = "a-b- "
    assert [text: t] == parse!(t)

    assert [text: "020-123 en mijn 010-123"] ===
             parse!("020-123 en mijn 010-123")

    assert {:ok,
            [
              {:modifier, "strong", [{:emphasis, "strong"}]}
            ]} === parse("++strong++")

    assert {:ok,
            [
              {:modifier, "strong", [{:emphasis, "strong"}]},
              {:text, " "},
              {:modifier, "med", [{:emphasis, "moderate"}]},
              {:text, " "},
              {:modifier, "moderate", [{:emphasis, "none"}]},
              {:text, " "},
              {:modifier, "reduced", [{:emphasis, "reduced"}]}
            ]} === parse("++strong++ +med+ ~moderate~ -reduced-")
  end

  test "special characters" do
    text = """
    This is text with (parens) but this and other special characters: []()*~@#\\_!+- are ignored
    """

    assert [text: text] === parse!(text)

    text = """
    This is text with ~parens! but this and other special characters: *~@#\\_!+- are ignored
    """

    assert [text: text] === parse!(text)
  end

  test "modifier AST" do
    assert [{:modifier, "hallo", [{:lang, "NL"}]}] ===
             parse!("(hallo)[lang:\"NL\"]")

    assert [
             {:text, "Your balance is: "},
             {:modifier, "12345",
              [number: nil, emphasis: "strong", whisper: nil, pitch: "high"]},
             {:text, ".\n"}
           ] ===
             parse!("""
             Your balance is: (12345)[number;emphasis:"strong";whisper;pitch:"high"].
             """)
  end
end
