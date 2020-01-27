defmodule SpeechMarkdown.Grammar.Test do
  use ExUnit.Case, async: true

  import SpeechMarkdown.Grammar

  test "parse" do
    assert parse(
             "hello [bla] there [x:\"bar\"] and (baz)[foo:\"bar\";lang:\"nl\"] that is it\n\n#[foo]\nxxx"
           )
           |> IO.inspect(label: "x")

    # # unsupported markup
    # assert parse("") === {:ok, []}
    # assert parse!(" ") === [text: " "]
    # assert parse!("(") === [text: "("]
    # assert parse!(")") === [text: ")"]
    # assert parse!("[") === [text: "["]
    # assert parse!("]") === [text: "]"]
    # assert parse!("()[]") === [text: "()[]"]
    # assert parse!("[invalid]") === [text: "[invalid]"]
    # assert parse!("[break:]") === [text: "[break:]"]
    # assert parse!("[5m]") === [text: "[5m]"]
    # assert parse!("(pecan)[ipa:]") === [text: "(pecan)[ipa:]"]
    # assert parse!("(pecan)[/]") === [text: "(pecan)[/]"]
    # assert parse!("[/pɪˈkɑːn/]") === [text: "[/pɪˈkɑːn/]"]
    # assert parse!("(pecan)[whisper]") === [text: "(pecan)[whisper]"]
    # assert parse!("(pecan))[/pɪˈkɑːn/]") === [text: "(pecan))[/pɪˈkɑːn/]"]

    # # breaks
    # assert parse!("[ 100ms]") === [break: [100, :ms]]
    # assert parse!("[2s ]") === [break: [2, :s]]
    # assert parse!("[ break : 5s ]") === [break: [5, :s]]

    # # ipa
    # assert parse!("(pecan)[ /pɪˈkɑːn/]") === [
    #          modifier: ["pecan", ipa: "pɪˈkɑːn"]
    #        ]

    # assert parse!("(pecan)[ipa : \"pɪˈkɑːn\" ]") === [
    #          modifier: ["pecan", ipa: "pɪˈkɑːn"]
    #        ]

    # # say-as
    # assert parse!("(www)[ characters]") === [
    #          modifier: ["www", say: :characters]
    #        ]

    # assert parse!("(1234)[number ]") === [
    #          modifier: ["1234", say: :number]
    #        ]
  end
end
