defmodule SpeechMarkdown.Grammar do
  @moduledoc """
  This is the nimble-parsec grammar for the subset of the Speech Markdown
  language supported by this library. The parser is tolerant of any string
  inputs, but poorly-specified constructs will simply be output as string
  values. Results are returned as an ast containing a list of tagged tokens,
  like so:

    iex> parse!("You say pecan [200ms], I say (pecan)[/pɪˈkɑːn/]")
    [
      text: "You say pecan ",
      break: [200, :ms],
      text: ", I say ",
      modifier: ["pecan", {:ipa, "pɪˈkɑːn"}]
    ]

  """

  import NimbleParsec

  @doc "parse a speech markdown string into an ast"
  @spec parse!(text :: String.t()) :: keyword()
  def parse!(text) do
    {:ok, ast} = parse(text)
    ast
  end

  @doc "parse a speech markdown string into an ast"
  @spec parse(text :: String.t()) :: {:ok, keyword()}
  def parse(text) do
    case document(text) do
      {:ok, [ast], "", _, _, _} ->
        {:ok, ast}

      {:ok, [_], rest, _, _, _} ->
        {:error, "Incomplete input near: " <> rest}

      r ->
        r
    end
  end

  # coalesce adjacent text tokens
  defp merge([{:text, x}, {:text, y} | z]) do
    merge([{:text, x <> y} | z])
  end

  defp merge([x | y]) do
    [x | merge(y)]
  end

  defp merge([]) do
    []
  end

  # --------------------------------------------------------------------------
  # helpers
  # --------------------------------------------------------------------------
  atomize = &map(string(empty(), &1), {String, :to_atom, []})
  space = repeat(ascii_char('\r\n\s\t'))

  identifier =
    reduce(
      repeat(ascii_char('_abcdefghijklmnopqrstuvwxyz1234567890')),
      :to_string
    )

  single_quoted =
    ignore(string("'"))
    |> reduce(repeat(utf8_char([{:not, ?'}])), :to_string)
    |> ignore(string("'"))

  double_quoted =
    ignore(string("\""))
    |> reduce(repeat(utf8_char([{:not, ?"}])), :to_string)
    |> ignore(string("\""))

  defparsec(
    :keyvalue,
    identifier
    |> ignore(string(":"))
    |> choice([single_quoted, double_quoted])
    |> optional(
      ignore(string(";"))
      |> concat(parsec(:keyvalue))
    )
    |> reduce(:x)
  )

  defp kv([{:kv, [k, v]} | rest]) do
    [{k, v} | rest]
  end

  section =
    ignore(string("#"))
    |> parsec(:block)
    |> tag(:section)

  parenthesized =
    ignore(string("("))
    |> reduce(repeat(utf8_char([{:not, ?)}])), :to_string)
    |> ignore(string(")"))
    |> parsec(:block)
    |> tag(:paren_block)
    |> map(:x)

  def x(x) do
    IO.inspect(x, label: "x")
  end

  # --------------------------------------------------------------------------
  # breaks
  # --------------------------------------------------------------------------
  defparsec(
    :block,
    ignore(string("["))
    |> choice([
      parsec(:keyvalue) |> tag(:kv_block),
      identifier |> tag(:block)
    ])
    |> ignore(string("]"))
  )

  text =
    utf8_char([{:not, ?[}])
    |> reduce(:to_string)
    |> unwrap_and_tag(:text)

  defparsec(
    :document,
    choice([section, parenthesized, parsec(:block), text])
    |> repeat()
    |> reduce(:merge)
  )
end
