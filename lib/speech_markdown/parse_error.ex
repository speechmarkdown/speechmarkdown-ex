defmodule SpeechMarkdown.ParseError do
  @moduledoc """
  Raised when a Speech Markdown string failes to parse using SpeechMarkdown.to_ssml!/2
  """

  defexception message: "Syntax error"

  def new(reason) when is_binary(reason) do
    %__MODULE__{message: reason}
  end

  def new(reason) do
    %__MODULE__{message: inspect(reason)}
  end
end
