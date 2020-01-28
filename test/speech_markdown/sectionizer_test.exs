defmodule SpeechMarkdown.SectionizerTest do
  use ExUnit.Case

  import SpeechMarkdown.Sectionizer
  import SpeechMarkdown.Grammar
  import SpeechMarkdown.Validator

  test "sectionizer" do
    ast = [
      {:text, "Hello"},
      {:section, {:block, "excited"}},
      {:text, "Hello"}
    ]

    assert [{:text, "Hello"}, {:section, {:block, "excited"}, [text: "Hello"]}] =
             sectionize!(ast)
  end

  test "full sectionizer run" do
    smd = """
    Normal speech.
    #[dj]
    Switching to a music/media announcer.
    #[defaults]
    Now back to normal speech.
    """

    ast =
      smd
      |> parse!()
      |> validate!()
      |> sectionize!()

    assert [{:text, _}, {:section, _, [{:text, _}]}, {:text, _}] = ast
  end
end
