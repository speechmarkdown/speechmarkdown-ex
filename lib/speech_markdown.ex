defmodule SpeechMarkdown do
  @moduledoc """
  Elixir implementation for the Speech Markdown format.

  https://www.speechmarkdown.org/

  """

  alias SpeechMarkdown.Grammar
  alias SpeechMarkdown.Validator
  alias SpeechMarkdown.Sectionizer
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
    with {:ok, parsed} <- Grammar.parse(input),
         {:ok, validated} <- Validator.validate(parsed),
         {:ok, sectionized} <- Sectionizer.sectionize(validated) do
      Transpiler.transpile(sectionized, options)
    end
  end

  def to_ssml!(input, options \\ []) do
    {:ok, output} = to_ssml(input, options)
    output
  end

  @doc """
  Convert the given Speech Markdown into plain text
  """
  def to_plaintext(input) do
    with {:ok, parsed} <- Grammar.parse(input) do
      Transpiler.plaintext(parsed)
    end
  end

  def to_plaintext!(input) do
    {:ok, output} = to_plaintext(input)
    output
  end
end
