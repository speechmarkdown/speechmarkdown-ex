defmodule SpeechMarkdown.Grammar.Test do
  use ExUnit.Case, async: true

  import SpeechMarkdown.Grammar

  test "parse" do
    assert {:ok, _} = parse("++strong++")

    assert {:ok, _} = parse("++strong++ +med+ ~moderate~ -reduced-")

    # # unsupported markup
    assert {:ok, _} = parse("")
    assert {:ok, _} = parse(" ")
    assert {:ok, _} = parse("(")
    #    assert {:ok, _} = parse(")")
    #   assert {:ok, _} = parse("[")
    assert {:ok, _} = parse("]")
    assert {:ok, _} = parse("()[]")
    assert {:ok, _} = parse("[invalid]")
    # assert {:ok, _} = parse("[break:]")
    assert {:ok, _} = parse("[5m]")
    # assert {:ok, _} = parse("(pecan)[ipa:]")
    # assert {:ok, _} = parse("(pecan)[/]")
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

    assert parse(
             "hello [bla] there [x:\"bar\"] and (foo [300ms] (d)[x] apentuin)[foo:\"bar\";lang:\"nl\"] that is it\n\n#[foo]\nxxx"
           )
  end
end
