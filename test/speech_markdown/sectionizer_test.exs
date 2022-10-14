defmodule SpeechMarkdown.SectionizerTest do
  use ExUnit.Case, async: true

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
             sectionize(ast)
  end

  test "full sectionizer run" do
    smd = """
    Normal speech.
    #[dj]
    Switching to a music/media announcer.
    #[defaults]
    Now back to normal speech.
    """

    ast = smd |> parse!()

    assert :ok = validate(ast)

    assert [{:text, _}, {:section, _, [{:text, _}]}, {:text, _}] =
             sectionize(ast)
  end
end
