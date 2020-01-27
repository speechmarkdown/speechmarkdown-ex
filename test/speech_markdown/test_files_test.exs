defmodule SpeechMarkdown.TestFilesTest do
  use ExUnit.Case, async: true

  defmodule Helper do
    @base "#{__DIR__}/../fixtures/speechmarkdown-test-files/test-data/"

    def fixture(test) do
      base = @base <> test <> "/" <> test

      {
        File.read!(base <> ".smd") |> String.trim(),
        # |> String.replace("\n", ""),
        File.read!(base <> ".alexa.ssml"),
        # |> String.replace("\n", ""),
        File.read!(base <> ".google.ssml"),
        File.read!(base <> ".txt") |> String.trim()
      }
    end

    def paths() do
      Path.wildcard(@base <> "*") |> Enum.filter(&File.dir?/1)
    end
  end

  import SpeechMarkdown, only: [to_ssml: 2, to_plaintext: 1]

  for path <- Helper.paths() do
    testcase = Path.basename(path)
    {smd, alexa, google, txt} = Helper.fixture(testcase)

    test "#{testcase} - Alexa" do
      assert {:ok, unquote(alexa)} = to_ssml(unquote(smd), variant: :alexa)
    end

    test "#{testcase} - Google Assistant" do
      assert {:ok, unquote(google)} = to_ssml(unquote(smd), variant: :google)
    end

    test "#{testcase} - plain text" do
      assert {:ok, unquote(txt)} === to_plaintext(unquote(smd))
    end
  end
end
