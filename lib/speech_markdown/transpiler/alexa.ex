defmodule SpeechMarkdown.Transpiler.Alexa do
  @moduledoc false

  defdelegate ch(s), to: String, as: :to_charlist

  @alexa_voices %{
                  "Ivy" => "en-US",
                  "Joanna" => "en-US",
                  "Joey" => "en-US",
                  "Justin" => "en-US",
                  "Kendra" => "en-US",
                  "Kimberly" => "en-US",
                  "Matthew" => "en-US",
                  "Salli" => "en-US",
                  "Nicole" => "en-AU",
                  "Russell" => "en-AU",
                  "Amy" => "en-GB",
                  "Brian" => "en-GB",
                  "Emma" => "en-GB",
                  "Aditi" => "en-IN",
                  "Raveena" => "en-IN",
                  "Hans" => "de-DE",
                  "Marlene" => "de-DE",
                  "Vicki" => "de-DE",
                  "Conchita" => "es-ES",
                  "Enrique" => "es-ES",
                  "Carla" => "it-IT",
                  "Giorgio" => "it-IT",
                  "Mizuki" => "ja-JP",
                  "Takumi" => "ja-JP",
                  "Celine" => "fr-FR",
                  "Lea" => "fr-FR",
                  "Mathieu" => "fr-FR"
                }
                |> Map.keys()

  def lookup_voice(voice) do
    Enum.find(@alexa_voices, &(String.downcase(&1) == String.downcase(voice)))
  end
end
