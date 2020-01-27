defmodule SpeechMarkdown do
  alias SpeechMarkdown.Transpiler

  @type options() :: [option()]

  @type option() ::
          {:xml_declaration, boolean()}
          | {:variant, :google | :alexa | :plaintext}

  @doc """
  Convert the given Speech Markdown into SSML.

  Options:

  - `xml_declaration` - boolean to indicate whether we need the XML
    declaration in the output, default `false`

  """
  def to_ssml(input, options \\ []) do
    Transpiler.transpile(input, options)
  end

  @doc """
  Convert the given Speech Markdown into plain text
  """
  def to_plaintext(input) do
    Transpiler.transpile(input, variant: :plaintext)
  end
end
