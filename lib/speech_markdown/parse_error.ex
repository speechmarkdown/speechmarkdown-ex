defmodule SpeechMarkdown.ParseError do
  defexception message: "Syntax error"

  def new(reason) when is_binary(reason) do
    %__MODULE__{message: reason}
  end

  def new(reason) do
    %__MODULE__{message: inspect(reason)}
  end
end
