defmodule SpeechMarkdown.TestFilesTest.Helper do
  @base "#{__DIR__}/../fixtures/speechmarkdown-test-files/test-data/"

  def fixture(test) do
    base = @base <> test <> "/" <> test

    {
      File.read!(base <> ".smd") |> String.trim(),
      # |> String.replace("\n", ""),
      n(File.read!(base <> ".alexa.ssml")),
      # |> String.replace("\n", ""),
      n(File.read!(base <> ".google.ssml")),
      File.read!(base <> ".txt") |> String.trim()
    }
  end

  def paths() do
    Path.wildcard(@base <> "*") |> Enum.filter(&File.dir?/1)
  end

  @doc """
  Normalize the output
  """
  def n({:ok, result}) do
    {:ok, n(result)}
  end

  def n(result) do
    result = Regex.replace(~r/\n/, result, "")
    Regex.replace(~r/\s+/, result, " ")
  end
end

defmodule SpeechMarkdown.TestFilesTest do
  use ExUnit.Case, async: true

  import SpeechMarkdown, only: [to_ssml: 2, to_plaintext: 1]
  import SpeechMarkdown.TestFilesTest.Helper

  for path <- SpeechMarkdown.TestFilesTest.Helper.paths() do
    testcase = Path.basename(path)

    {smd, alexa, google, txt} =
      SpeechMarkdown.TestFilesTest.Helper.fixture(testcase)

    test "#{testcase} - Alexa" do
      assert {:ok, result} = to_ssml(unquote(smd), variant: :alexa)
      assert unquote(alexa) === n(result)
    end

    test "#{testcase} - Google Assistant" do
      assert {:ok, result} = to_ssml(unquote(smd), variant: :google)
      assert unquote(google) === n(result)
    end

    # test "#{testcase} - plain text" do
    #   assert {:ok, unquote(txt)} === to_plaintext(unquote(smd))
    # end
  end
end
