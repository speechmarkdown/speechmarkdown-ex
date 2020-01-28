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
  # FIXME whitespace
  space = ignore(repeat(ascii_char('\r\n\s\t')))
  non_ws_char = utf8_char([9, 10, 11, 12, 13, 32] |> Enum.map(&{:not, &1}))

  identifier =
    reduce(
      ascii_char('_abcdefghijklmnopqrstuvwxyz1234567890')
      |> concat(repeat(ascii_char('_abcdefghijklmnopqrstuvwxyz1234567890'))),
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
    |> optional(space)
    |> ignore(string(":"))
    |> optional(space)
    |> choice([single_quoted, double_quoted])
    |> optional(
      ignore(string(";"))
      |> optional(space)
      |> concat(parsec(:keyvalue))
    )
  )

  section =
    ignore(string("#"))
    |> parsec(:block)
    |> unwrap_and_tag(:section)

  audio =
    ignore(string("!["))
    |> choice([single_quoted, double_quoted])
    |> ignore(string("]"))
    |> unwrap_and_tag(:audio)

  defp empty_block(_x) do
    :empty_block
  end

  parenthesized =
    ignore(string("("))
    |> reduce(repeat(utf8_char([{:not, ?)}])), :to_string)
    #    |> concat(parsec(:document))
    |> ignore(string(")"))
    |> choice([parsec(:block), string("[]") |> reduce(:empty_block)])
    |> reduce(:nested_block)

  ipa =
    ignore(string("/"))
    |> reduce(repeat(utf8_char([{:not, ?/}])), :to_string)
    |> ignore(string("/"))
    |> unwrap_and_tag(:ipa)

  # --------------------------------------------------------------------------
  # breaks
  # --------------------------------------------------------------------------
  defparsec(
    :block,
    ignore(string("["))
    |> optional(space)
    |> choice([
      single_quoted |> unwrap_and_tag(:sub),
      double_quoted |> unwrap_and_tag(:sub),
      ipa,
      parsec(:keyvalue) |> reduce(:kv_block),
      identifier |> unwrap_and_tag(:block)
    ])
    |> optional(space)
    |> ignore(string("]"))
  )

  def nested_block([a, b]) do
    {:nested_block, [{:text, a}], b}
  end

  def kv_block(x) do
    {:kv_block, kv_block1(x, [])}
  end

  def kv_block1([], acc), do: acc

  def kv_block1([k, v | rest], acc) do
    kv_block1(rest, [{k, v} | acc])
  end

  @ws [9, 10, 11, 12, 13, 32]
  ws = ascii_char(@ws)
  non_ws = utf8_char(@ws |> Enum.map(&{:not, &1}))

  non_ctrl_instr =
    utf8_char((@ws ++ [?), ?], ?[, ?(, 35, ?!]) |> Enum.map(&{:not, &1}))

  # [{:not, ?[}, {:not, ?)}])
  plaintext =
    utf8_char([])
    |> reduce(:to_string)
    |> unwrap_and_tag(:text)

  emphasized = fn abbrev, emphasis ->
    <<char, _::binary>> = abbrev

    empty()
    |> ignore(string(abbrev))
    |> concat(non_ctrl_instr)
    |> repeat(utf8_char([{:not, char}]))
    |> reduce(:to_string)
    |> ignore(string(abbrev))
    |> lookahead(choice([ws, eos()]))
    |> reduce({:short_emphasis, [emphasis]})
  end

  defparsec(
    :any_emphasis,
    choice([
      emphasized.("++", "strong"),
      emphasized.("+", "moderate"),
      emphasized.("~", "none"),
      emphasized.("-", "reduced")
    ])
    |> lookahead_not(ascii_char([?a..?z, ?A..?Z, ?0..?9]))
  )

  defparsec(
    :document,
    choice([
      parenthesized,
      section,
      audio,
      parsec(:block),
      parsec(:any_emphasis),
      plaintext
    ])
    # choice([section, audio, parenthesized, parsec(:block), strong, plaintext])
    |> repeat()
    |> reduce(:merge)
  )

  defp short_emphasis([text], emphasis) do
    {:nested_block, [text: text], {:kv_block, [{"emphasis", emphasis}]}}
  end
end
