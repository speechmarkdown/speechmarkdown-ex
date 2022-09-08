defmodule SpeechMarkdownAdditionalCasesTest do
  @moduledoc """
  Cover some additional (in-spec) SMD cases
  """
  use ExUnit.Case, async: true

  import SpeechMarkdown, only: [to_ssml: 2, to_plaintext: 1]
  import SpeechMarkdown.TestSupport.FixtureHelper

  @cases [
    # phone / telephone
    {"(31641322599)[phone]",
     "<speak><say-as interpret-as=\"telephone\">31641322599</say-as></speak>",
     "31641322599"},
    # currency
    {"(€200)[currency]",
     "<speak><say-as interpret-as=\"currency\" language=\"en-US\">€200</say-as></speak>",
     "€200"},
    # verbatim
    {"(abc)[verbatim]",
     "<speak><say-as interpret-as=\"verbatim\">abc</say-as></speak>", "abc"},
    # cardinal
    {"(12345)[cardinal]",
     "<speak><say-as interpret-as=\"cardinal\">12345</say-as></speak>", "12345"}
  ]

  for {smd, ssml, txt} <- @cases do
    test "SMD #{smd}" do
      assert {:ok, result} = to_ssml(unquote(smd), variant: :general)
      assert_xml(unquote(ssml) == result)

      assert {:ok, result} = to_plaintext(unquote(smd))
      assert unquote(txt) == result
    end
  end
end
