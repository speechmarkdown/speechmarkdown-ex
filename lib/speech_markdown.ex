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

  Currently, SMD → SSML support is available in a general variant, and
  specific SSML variants for the Amazon Alexa and Google Assistant
  platforms.

  """

  alias SpeechMarkdown.{Grammar, ParseError, Sectionizer, Transpiler, Validator}

  @type options() :: [option()]

  @type option() ::
          {:xml_declaration, boolean()}
          | {:variant, :general | :google | :alexa}
          | {:validate, :strict | :loose}

  @doc """
  Convert the given Speech Markdown into SSML.

  Options:

  - `xml_declaration` - boolean to indicate whether we need the XML
    declaration in the output, default `false`

  - `variant` - Which SSML variant to choose from. Either `:general`,
    `:alexa` or `:google`; defaults to `:general`.

  - `validate` - `:strict` (default) or `:loose`; when strict, return
    error when encountering invalid syntax, unknown attributes or
    unknown attribute values; when `:loose`, such errors are ignored.

  """
  @spec to_ssml(input :: String.t(), options()) ::
          {:ok, String.t()} | {:error, term()}
  def to_ssml(input, options \\ []) when is_binary(input) do
    validate = Keyword.get(options, :validate, :strict)

    with {:ok, parsed} <- Grammar.parse(input),
         :ok <- Validator.validate(parsed) |> validate_result(validate) do
      parsed
      |> Sectionizer.sectionize()
      |> Transpiler.transpile(options)
    end
  end

  @spec to_ssml!(input :: String.t(), options()) :: String.t()
  def to_ssml!(input, options \\ []) when is_binary(input) do
    case to_ssml(input, options) do
      {:ok, output} -> output
      {:error, reason} -> raise ParseError.new(reason)
    end
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
    case to_plaintext(input) do
      {:ok, output} -> output
      {:error, reason} -> raise ParseError.new(reason)
    end
  end

  defp validate_result(_, :loose), do: :ok
  defp validate_result(r, :strict), do: r
end
