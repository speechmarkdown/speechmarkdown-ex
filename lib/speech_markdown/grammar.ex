defmodule SpeechMarkdown.Grammar do
  @moduledoc false

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

  space = ignore(repeat(ascii_char('\r\n\s\t')))

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
    |> reduce(:finalize_section)

  audio =
    ignore(string("!["))
    |> choice([single_quoted, double_quoted])
    |> ignore(string("]"))
    |> unwrap_and_tag(:audio)

  defp empty_block(_x) do
    :empty_block
  end

  defparsec(
    :modifier,
    ignore(string("("))
    |> reduce(repeat(utf8_char([{:not, ?)}])), :to_string)
    # |> concat(parsec(:document))
    |> ignore(string(")"))
    |> choice([parsec(:block), string("[]") |> reduce(:empty_block)])
    |> reduce(:finalize_modifier)
  )

  ipa =
    ignore(string("/"))
    |> reduce(repeat(utf8_char([{:not, ?/}])), :to_string)
    |> ignore(string("/"))
    |> unwrap_and_tag(:ipa)

  # --------------------------------------------------------------------------
  # breaks
  # --------------------------------------------------------------------------

  defparsec(
    :block_inner,
    choice([
      single_quoted |> unwrap_and_tag(:sub),
      double_quoted |> unwrap_and_tag(:sub),
      ipa,
      identifier
      |> optional(
        ignore(string(":"))
        |> choice([single_quoted, double_quoted])
      )
      |> tag(:i)
    ])
    |> optional(ignore(string(";")))
  )

  defparsec(
    :block,
    ignore(string("["))
    |> optional(space)
    |> parsec(:block_inner)
    |> repeat(parsec(:block_inner))
    |> reduce(:finalize_block)
    |> optional(space)
    |> ignore(string("]"))
  )

  defp finalize_block(b) do
    {:block,
     Enum.map(
       b,
       fn
         {:i, [<<x, _::binary>> = v]} when x >= ?0 and x <= ?9 -> {:break, v}
         {:i, [k]} -> {String.to_atom(k), nil}
         {:i, [k, v]} -> {String.to_atom(k), v}
         {:ipa, v} -> {:ipa, v}
         {:sub, v} -> {:sub, v}
       end
     )}
  end

  defp finalize_modifier([text, :empty_block]) do
    {:text, text}
  end

  defp finalize_modifier([text, {:block, block}]) do
    {:modifier, text, block}
  end

  defp finalize_section([{:block, block}]) do
    {:section, block}
  end

  @ws [9, 10, 11, 12, 13, 32]
  ws = ascii_char(@ws)

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
      parsec(:modifier),
      section,
      audio,
      parsec(:block),
      parsec(:any_emphasis),
      plaintext
    ])
    # choice([section, audio, modifier, parsec(:block), strong, plaintext])
    |> repeat()
    |> reduce(:merge)
  )

  defp short_emphasis([text], emphasis) do
    {:modifier, text, [emphasis: emphasis]}
  end
end
