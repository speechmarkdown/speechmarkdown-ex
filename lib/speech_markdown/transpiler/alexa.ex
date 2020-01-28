defmodule SpeechMarkdown.Transpiler.Alexa do
  defdelegate ch(s), to: String, as: :to_charlist

  @emotions ~w(excited disappointed)
  @intensities ~w(x-low low medium high x-high)

  def emotions(), do: @emotions

  def emotion(inner, "dj") do
    {:"amazon:domain", [name: 'music'], inner}
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
