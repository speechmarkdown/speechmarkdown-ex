defmodule SpeechMarkdowntendedCasesTests do
  use ExUnit.Case, async: true

  import SpeechMarkdown, only: [to_ssml: 2, to_plaintext: 1]
  import SpeechMarkdown.TestSupport.FixtureHelper

  # out-of-spec SMD cases

  @cases [
    # SSML mark
    {"$[a]", "<speak><mark name=\"a\" /></speak>", ""}
  ]

  for {smd, ssml, txt} <- @cases do
    test "SMD #{smd}" do
      assert {:ok, result} = to_ssml(unquote(smd), variant: :generic)
      assert_xml(unquote(ssml) == result)

      assert {:ok, result} = to_plaintext(unquote(smd))
      assert unquote(txt) == result
    end
  end
end
