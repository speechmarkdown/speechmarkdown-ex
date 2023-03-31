defmodule SpeechMarkdownTest do
  use ExUnit.Case, async: true

  import SpeechMarkdown
  alias SpeechMarkdown.ParseError

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

  describe "validation mode" do
    test "default" do
      assert {:error, {:invalid_instruction, [bar: nil]}} ===
               to_ssml("foo [bar]")

      assert_raise ParseError, fn -> to_ssml!("foo [bar]") end

      assert {:error, {:invalid_attribute, :bar}} ===
               to_ssml("foo (baz)[bar:\"bla\"]")

      assert_raise ParseError, fn -> to_ssml!("foo (baz)[bar:\"bla\"]") end
    end

    test ":strict" do
      assert {:error, {:invalid_instruction, [bar: nil]}} ===
               to_ssml("foo [bar]", validate: :strict)

      assert_raise ParseError, fn ->
        to_ssml!("foo [bar]", validate: :strict)
      end

      assert {:error, {:invalid_attribute, :bar}} ===
               to_ssml("foo (baz)[bar:\"bla\"]", validate: :strict)

      assert_raise ParseError, fn ->
        to_ssml!("foo (baz)[bar:\"bla\"]", validate: :strict)
      end
    end

    test ":loose" do
      assert {:ok, "<speak>foo </speak>"} ===
               to_ssml("foo [bar]", validate: :loose)

      assert {:ok, "<speak>foo baz</speak>"} ===
               to_ssml("foo (baz)[bar:\"bla\"]", validate: :loose)

      assert {:ok,
              "<speak>foo <prosody volume=\"veryloud\">baz</prosody></speak>"} =
               to_ssml(
                 """
                 foo (baz)[bar:"bla";volume:"veryloud"]
                 """,
                 validate: :loose
               )

      assert {:ok, "<speak>foo</speak>"} ===
               to_ssml("#[sectionbla]\nfoo", validate: :loose)

      assert {:ok, "<speak>foo\n</speak>"} ===
               to_ssml("#[x;d;d:\"d\"]\nfoo\n#[another]", validate: :loose)
    end
  end

  describe "variants" do
    @alexa_voice "#[voice:\"Kendra\"] Section 1"
    @google_voice "#[voice:\"nl-NL-Standard-A\"] Section 1"

    test "general" do
      assert {:ok, "<speak><voice name=\"Kendra\">Section 1</voice></speak>"} =
               to_ssml(@alexa_voice, variant: :general)

      assert {:ok,
              "<speak><voice name=\"nl-NL-Standard-A\">Section 1</voice></speak>"} =
               to_ssml(@google_voice, variant: :general)
    end

    test "alexa" do
      assert {:ok, "<speak><voice name=\"Kendra\">Section 1</voice></speak>"} =
               to_ssml(@alexa_voice, variant: :alexa)

      assert {:ok, "<speak>Section 1</speak>"} =
               to_ssml(@google_voice, variant: :alexa)
    end

    test "google" do
      assert {:ok, "<speak>Section 1</speak>"} =
               to_ssml(@alexa_voice, variant: :google)

      assert {:ok,
              "<speak><voice name=\"nl-NL-Standard-A\">Section 1</voice></speak>"} =
               to_ssml(@google_voice, variant: :google)
    end
  end
end
