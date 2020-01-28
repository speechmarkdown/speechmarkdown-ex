defmodule SpeechMarkdownTest do
  use ExUnit.Case

  import SpeechMarkdown

  describe "to_ssml" do
    test "to_ssml" do
      assert to_ssml("", []) === {:ok, ~s|<speak/>|}

      assert to_ssml("", xml_declaration: true) ===
               {:ok, ~s|<?xml version="1.0"?><speak/>|}

      assert to_ssml!("text", []) ===
               ~s|<speak>text</speak>|

      # breaks
      assert to_ssml!("[200ms]", []) ===
               ~s|<speak><break time="200ms"/></speak>|

      assert to_ssml!("[5s]", []) ===
               ~s|<speak><break time="5s"/></speak>|

      # ipa
      assert to_ssml!("(pecan)[/pɪˈkɑːn/]", []) ===
               ~s|<speak><phoneme alphabet="ipa" ph="pɪˈkɑːn">pecan</phoneme></speak>|

      # say-as
      assert to_ssml!("(www)[characters]", []) ===
               ~s|<speak><say-as interpret-as="characters">www</say-as></speak>|

      assert to_ssml!("(1234)[number]", []) ===
               ~s|<speak><say-as interpret-as="number">1234</say-as></speak>|
    end
  end

  describe "to_plaintext" do
    test "to_plaintext" do
      assert to_plaintext!("text") === "text"
      assert to_plaintext!("text [200ms] with break") === "text with break"
      assert to_plaintext!("text with ++emphasis++") === "text with emphasis"

      assert to_plaintext!("text with (ac)[sub:\"alpha centauri\"]") ===
               "text with ac"
    end
  end
end
