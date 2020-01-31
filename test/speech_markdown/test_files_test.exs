defmodule SpeechMarkdown.TestFilesTest do
  use ExUnit.Case, async: true

  import SpeechMarkdown, only: [to_ssml: 2, to_plaintext: 1]
  import SpeechMarkdown.TestSupport.FixtureHelper

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
