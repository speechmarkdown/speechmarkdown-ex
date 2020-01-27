defmodule SpeechMarkdown.TestFilesTest do
  use ExUnit.Case, async: true

  defmodule Helper do
    @base "#{__DIR__}/../fixtures/speechmarkdown-test-files/test-data/"

    def fixture(test) do
      base = @base <> test <> "/" <> test

      {File.read!(base <> ".smd"), File.read!(base <> ".alexa.ssml"),
       File.read!(base <> ".google.ssml"), File.read!(base <> ".txt")}
    end

    def paths() do
      Path.wildcard(@base <> "*") |> Enum.filter(&File.dir?/1)
    end
  end

  import SpeechMarkdown.Transpiler

  for path <- Helper.paths() do
    testcase = Path.basename(path)
    {smd, alexa, google, txt} = Helper.fixture(testcase)

    test "#{testcase} - Alexa" do
      assert {:ok, unquote(alexa)} === transpile(unquote(smd))
    end

    test "#{testcase} - Google Assistant" do
      assert {:ok, unquote(google)} === transpile(unquote(smd))
    end

    test "#{testcase} - plain text" do
      assert {:ok, unquote(txt)} === transpile(unquote(smd))
    end
  end
end
