defmodule SpeechMarkdown.Transpiler.Alexa do
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

  @emotions ~w(excited disappointed)a
  @intensities ~w(x-low low medium high x-high)

  def emotion(emotion, intensity, text) do
    {:"amazon:emotion", [name: ch(emotion), intensity: ch(intensity)], text}
  end

  def emotions(), do: @emotions

  def emotion(inner, "dj") do
    {:"amazon:domain", [name: 'music'], inner}
  end

  def emotion(inner, "newscaster") do
    {:"amazon:domain", [name: 'news'], inner}
  end

  def emotion(inner, block) do
    case section_to_xml_attrs(block) do
      {:ok, attrs} ->
        {:"amazon:emotion", attrs, inner}

      :ignore ->
        inner
    end
  end

  defp section_to_xml_attrs({:block, emotion}),
    do: section_to_xml_attrs(emotion)

  defp section_to_xml_attrs([{emotion, intensity}])
       when emotion in @emotions do
    intensity = String.downcase(intensity)

    case valid_intensity?(intensity) do
      true ->
        {:ok, [name: ch(emotion), intensity: ch(intensity)]}

      false ->
        :ignore
    end
  end

  defp section_to_xml_attrs(emotion)
       when emotion in @emotions do
    {:ok, [name: ch(emotion), intensity: 'medium']}
  end

  defp section_to_xml_attrs(_), do: :ignore

  defp valid_intensity?(intensity) when intensity in @intensities, do: true
  defp valid_intensity?(_), do: false
end
