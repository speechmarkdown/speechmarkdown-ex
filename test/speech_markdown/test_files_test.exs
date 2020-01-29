defmodule SpeechMarkdown.TestFilesTest.Helper do
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

  def paths do
    Path.wildcard(@base <> "*") |> Enum.filter(&File.dir?/1)
  end

  @doc """
  XML assertion; generated XML might be semantically
  identical but different in string presentation; e.g. regarding
  ordering of element attributes.
  """

  defmacro assert_xml({:==, _, [a, b]}) do
    quote do
      import BubbleLib.XML

      parse_a = xml_parse(unquote(a))
      parse_b = xml_parse(unquote(b))

      assert parse_a === parse_b
    end
  end
end

defmodule SpeechMarkdown.TestFilesTest do
  use ExUnit.Case, async: true

  import SpeechMarkdown, only: [to_ssml: 2, to_plaintext: 1]
  import SpeechMarkdown.TestFilesTest.Helper

  for path <- paths() do
    testcase = Path.basename(path)

    {smd, alexa, google, txt} = fixture(testcase)

    describe "#{testcase}" do
      test "Alexa" do
        assert {:ok, result} = to_ssml(unquote(smd), variant: :alexa)
        assert_xml(unquote(alexa) == result)
      end

      test "Google Assistant" do
        assert {:ok, result} = to_ssml(unquote(smd), variant: :google)
        assert_xml(unquote(google) == result)
      end

      test "Plain text" do
        assert {:ok, result} = to_plaintext(unquote(smd))
        assert unquote(txt) == result
      end
    end
  end
end
