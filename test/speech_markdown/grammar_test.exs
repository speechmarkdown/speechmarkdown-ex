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

    assert {:ok, _} = parse("[/pɪˈkɑːn/]")
    assert {:ok, _} = parse("(pecan)[whisper]")
    assert {:ok, _} = parse("(pecan)[/pɪˈkɑːn/]")

    # # breaks
    assert {:ok, _} = parse("[ 100ms]")
    assert {:ok, _} = parse("[2s ]")
    assert {:ok, _} = parse("[ break : \"5s\" ]")

    # # ipa
    assert {:ok, _} = parse("(pecan)[ /pɪˈkɑːn/]")

    assert {:ok, _} = parse("(pecan)[ipa : \"pɪˈkɑːn\" ]")

    # say-as
    assert {:ok, _} = parse("(www)[ characters]")
    assert {:ok, _} = parse("(1234)[number ]")
    assert {:ok, _} = parse("![\"http://audio.mp3\"]")
    assert {:ok, _} = parse("[\"aluminum\"]")
    assert {:ok, _} = parse("(Al)[\"aluminum\"]")
  end

  test "large test case" do
    assert parse(
             "hello [400ms] xxx  [bla;bar;x:\"d\";\"dd\"] there [x:\"bar\"] and (foo [300ms] (d)[x] apentuin)[foo:\"bar\";lang:\"nl\"] that is it\n\n#[foo]\nxxx"
           )

    #           |> IO.inspect(label: "x")
  end

  test "emphasis" do
    assert [text: _] = parse!("foo - bar - baz")

    assert [text: _] = parse!("foo-bar-baz")

    assert {:ok,
            [
              {:nested_block, [text: "strong"],
               {:kv_block, [{"emphasis", "strong"}]}}
            ]} = parse("++strong++")

    assert {:ok,
            [
              {:nested_block, [text: "strong"],
               {:kv_block, [{"emphasis", "strong"}]}},
              {:text, " "},
              {:nested_block, [text: "med"],
               {:kv_block, [{"emphasis", "moderate"}]}},
              {:text, " "},
              {:nested_block, [text: "moderate"],
               {:kv_block, [{"emphasis", "none"}]}},
              {:text, " "},
              {:nested_block, [text: "reduced"],
               {:kv_block, [{"emphasis", "reduced"}]}}
            ]} = parse("++strong++ +med+ ~moderate~ -reduced-")
  end

  test "special chars" do
    text = """
    This is text with (parens) but this and other special characters: []()*~@#\\_!+- are ignored
    """

    assert [text: _] = parse!(text)

    text = """
    This is text with ~parens! but this and other special characters: *~@#\\_!+- are ignored
    """

    assert [text: _] = parse!(text)
  end

  test "modifier" do
    text = "(hallo)[lang:\"NL\"]"
    assert [{:modifier, "hallo", [{:lang, "NL"}]}] = parse!(text)
  end
end
