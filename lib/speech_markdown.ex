defmodule SpeechMarkdown do
  @moduledoc """
  Elixir implementation for the Speech Markdown format.

  https://www.speechmarkdown.org/

  The Speech Markdown transpiler converts the markdown text to the
  Speech Synthesis Markup Language (SSML) format. The results are
  returned as an SSML string.

  """

  alias SpeechMarkdown.{Grammar, Sectionizer, Transpiler, Validator}

  @type options() :: [option()]

  @type option() ::
          {:xml_declaration, boolean()}
          | {:variant, :google | :alexa | :plaintext}

  @doc """
  Convert the given Speech Markdown into SSML.

  Options:

  - `xml_declaration` - boolean to indicate whether we need the XML
    declaration in the output, default `false`

  - `variant` - Which SSML variant to choose from. Either `:alexa` or
    `:google`; defaults to `:alexa`, as Alexa has most SSML features.
  """
  def to_ssml(input, options \\ []) do
    with {:ok, parsed} <- Grammar.parse(input),
         {:ok, validated} <- Validator.validate(parsed) do
      validated
      |> Sectionizer.sectionize()
      |> Transpiler.transpile(options)
    end
  end

  def to_ssml!(input, options \\ []) do
    {:ok, output} = to_ssml(input, options)
    output
  end

  @doc """
  Convert the given Speech Markdown into plain text.
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
