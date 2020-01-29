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

  defmacro assert_xml({:==, _, [a, b]}) do
    quote do
      import BubbleLib.XML

      if unquote(a) !== unquote(b) do
        parse_a = xml_parse(unquote(a))
        parse_b = xml_parse(unquote(b))

        assert parse_a === parse_b
      else
        assert unquote(a) === unquote(b)
      end
    end
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
      assert_xml(unquote(alexa) == n(result))
    end

    test "#{testcase} - Google Assistant" do
      assert {:ok, result} = to_ssml(unquote(smd), variant: :google)
      assert_xml(unquote(google) == result)
    end

    test "#{testcase} - plain text" do
      assert {:ok, result} = to_plaintext(unquote(smd))
      assert unquote(txt) == result
    end
  end
end
