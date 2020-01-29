defmodule SpeechMarkdown do
  @moduledoc """
  Elixir implementation for the Speech Markdown format.

  https://www.speechmarkdown.org/

  Speech Markdown is a text format which is akin to regular Markdown,
  but with an alternative syntax and built for the purpose of
  generating platform-specific
  [SSML](https://en.wikipedia.org/wiki/Speech_Synthesis_Markup_Language)
  markup.

  The Speech Markdown transpiler converts the given Speeach Markdown text to the
  Speech Synthesis Markup Language (SSML) format. The results are
  returned as an SSML string.

  Currently, SMD → SSML support is available for the Alexa and Google
  Assistant dialects of SSML.

  """

  alias SpeechMarkdown.{Grammar, Sectionizer, Transpiler, Validator}

  @type options() :: [option()]

  @type option() ::
          {:xml_declaration, boolean()}
          | {:variant, :google | :alexa}
          | {:validate, :strict | :loose}

  @doc """
  Convert the given Speech Markdown into SSML.

  Options:

  - `xml_declaration` - boolean to indicate whether we need the XML
    declaration in the output, default `false`

  - `variant` - Which SSML variant to choose from. Either `:alexa` or
    `:google`; defaults to `:alexa`, as Alexa has most SSML features.

  - `validate` - `:strict` (default) or `:loose`; when strict, return
    error when encountering invalid syntax, unknown attributes or
    unknown attribute values; when `:loose`, such errors are ignored.

  """
  @spec to_ssml(input :: String.t(), options()) ::
          {:ok, String.t()} | {:error, term()}
  def to_ssml(input, options \\ []) when is_binary(input) do
    strict = Keyword.get(options, :validate, :strict) == :strict

    case strict do
      true ->
        with {:ok, parsed} <- Grammar.parse(input),
             :ok <- Validator.validate(parsed) do
          parsed
          |> Sectionizer.sectionize()
          |> Transpiler.transpile(options)
        end

      false ->
        with {:ok, parsed} <- Grammar.parse(input) do
          parsed
          |> Sectionizer.sectionize()
          |> Transpiler.transpile(options)
        end
    end
  end

  @spec to_ssml!(input :: String.t(), options()) :: String.t()
  def to_ssml!(input, options \\ []) when is_binary(input) do
    {:ok, output} = to_ssml(input, options)
    output
  end

  @doc """
  Convert the given Speech Markdown into plain text.
  """
  @spec to_plaintext(input :: String.t()) ::
          ssml :: {:ok, String.t()} | {:error, term()}
  def to_plaintext(input) when is_binary(input) do
    with {:ok, parsed} <- Grammar.parse(input) do
      Transpiler.plaintext(parsed)
    end
  end

  @spec to_plaintext!(input :: String.t()) :: ssml :: String.t()
  def to_plaintext!(input) when is_binary(input) do
    {:ok, output} = to_plaintext(input)
    output
  end
end
