defmodule SpeechMarkdown.Transpiler.Google do
  @moduledoc false

  @alexa_voices %{
                  "gl-ES-Standard-A" => "gl-ES",
                  "tr-TR-Standard-A" => "tr-TR",
                  "hi-IN-Neural2-A" => "hi-IN",
                  "yue-HK-Standard-A" => "yue-HK",
                  "sr-RS-Standard-A" => "sr-RS",
                  "ca-ES-Standard-A" => "ca-ES",
                  "nl-BE-Standard-A" => "nl-BE",
                  "en-GB-Neural2-A" => "en-GB",
                  "vi-VN-Standard-A" => "vi-VN",
                  "ja-JP-Neural2-B" => "ja-JP",
                  "en-IN-Standard-A" => "en-IN",
                  "id-ID-Standard-A" => "id-ID",
                  "da-DK-Standard-A" => "da-DK",
                  "de-DE-Neural2-B" => "de-DE",
                  "pl-PL-Standard-A" => "pl-PL",
                  "kn-IN-Standard-A" => "kn-IN",
                  "nl-NL-Standard-A" => "nl-NL",
                  "ru-RU-Standard-A" => "ru-RU",
                  "ml-IN-Standard-A" => "ml-IN",
                  "nb-NO-Standard-A" => "nb-NO",
                  "el-GR-Standard-A" => "el-GR",
                  "ko-KR-Neural2-A" => "ko-KR",
                  "cmn-TW-Standard-A" => "cmn-TW",
                  "gu-IN-Standard-A" => "gu-IN",
                  "is-IS-Standard-A" => "is-IS",
                  "sk-SK-Standard-A" => "sk-SK",
                  "en-AU-Neural2-A" => "en-AU",
                  "ar-XA-Standard-A" => "ar-XA",
                  "lv-LV-Standard-A" => "lv-LV",
                  "lt-LT-Standard-A" => "lt-LT",
                  "cs-CZ-Standard-A" => "cs-CZ",
                  "it-IT-Neural2-A" => "it-IT",
                  "hu-HU-Standard-A" => "hu-HU",
                  "pt-BR-Neural2-A" => "pt-BR",
                  "en-US-Neural2-A" => "en-US",
                  "sv-SE-Standard-A" => "sv-SE",
                  "he-IL-Standard-A" => "he-IL",
                  "ta-IN-Standard-A" => "ta-IN",
                  "es-US-Neural2-A" => "es-US",
                  "eu-ES-Standard-A" => "eu-ES",
                  "es-ES-Neural2-A" => "es-ES",
                  "fi-FI-Standard-A" => "fi-FI",
                  "pa-IN-Standard-A" => "pa-IN",
                  "fr-CA-Neural2-A" => "fr-CA",
                  "pt-PT-Standard-A" => "pt-PT",
                  "uk-UA-Standard-A" => "uk-UA",
                  "bg-BG-Standard-A" => "bg-BG",
                  "ms-MY-Standard-A" => "ms-MY",
                  "th-TH-Standard-A" => "th-TH",
                  "te-IN-Standard-A" => "te-IN",
                  "cmn-CN-Standard-A" => "cmn-CN",
                  "bn-IN-Standard-A" => "bn-IN",
                  "mr-IN-Standard-A" => "mr-IN",
                  "fr-FR-Neural2-A" => "fr-FR",
                  "af-ZA-Standard-A" => "af-ZA",
                  "fil-PH-Standard-A" => "fil-PH",
                  "ro-RO-Standard-A" => "ro-RO"
                }
                |> Map.keys()

  @doc """
  Find the proper, case-sensitive name of an Alexa voice.
  """
  @spec lookup_voice(String.t()) :: String.t() | nil
  def lookup_voice(voice) do
    Enum.find(@alexa_voices, &(String.downcase(&1) == String.downcase(voice)))
  end
end
