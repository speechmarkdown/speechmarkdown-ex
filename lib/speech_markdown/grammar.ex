defmodule SpeechMarkdown.Grammar do
  @moduledoc false

  @type attributes :: [{atom(), String.t()}]
  @type ast_node ::
          {:text, String.t()}
          | {:modifier, String.t(), attributes()}
          | {:block, attributes()}
          | {:break, String.t()}
          | {:section, attributes()}
          | {:section, attributes(), t()}
  @type t :: [ast_node()]

  import SpeechMarkdown.Normalizer, only: [normalize_block: 1]

  import NimbleParsec

  @doc "parse a speech markdown string into an ast"
  @spec parse!(text :: String.t()) :: t()
  def parse!(text) do
    {:ok, ast} = parse(text)
    ast
  end

  @doc "parse a speech markdown string into an ast"
  @spec parse(text :: String.t()) :: {:ok, t()} | {:error, term()}
  def parse(text) do
    case document(text) do
      {:ok, [ast], "", _, _, _} ->
        {:ok, ast}

      {:ok, [_], rest, _, _, _} ->
        {:error, "Incomplete input near: " <> rest}

      {:ok, _, _, _, _, _} ->
        {:error, "Failed to parse"}
    end
  end

  # --------------------------------------------------------------------------
  # helpers
  # --------------------------------------------------------------------------

  # coalesce adjacent text tokens
  defp merge([{:text, x}, {:text, y} | z]) do
    merge([{:text, x <> y} | z])
  end

  defp merge([x | y]) when is_integer(x) do
    merge([{:text, <<x>>} | y])
  end

  defp merge([x | y]) do
    [x | merge(y)]
  end

  defp merge([]) do
    []
  end

  defp empty_block(_), do: :empty_block

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
    |> normalize_block()
  end

  defp finalize_modifier([text, :empty_block]) do
    {:text, text}
  end

  defp finalize_modifier([text, {:block, block}]) do
    {:modifier, text, block}
  end

  defp finalize_section([{:block, [defaults: nil]}]) do
    {:section, []}
  end

  defp finalize_section([{:block, block}]) do
    {:section, block}
  end

  defp short_emphasis([text], emphasis) do
    {:modifier, text, [emphasis: emphasis]}
  end

  defp finalize_audio([url]) do
    {:audio, nil, url}
  end

  defp finalize_audio([caption, url]) do
    {:audio, caption, url}
  end

  # --------------------------------------------------------------------------
  # grammar
  # --------------------------------------------------------------------------

  @ws [9, 10, 11, 12, 13, 32]
  ws = ascii_char(@ws)
  space = ignore(repeat(ascii_char(@ws)))

  non_ctrl_instr =
    utf8_char((@ws ++ [?), ?], ?[, ?(, 35, ?!]) |> Enum.map(&{:not, &1}))

  identifier =
    times(ascii_char('_abcdefghijklmnopqrstuvwxyz1234567890'), min: 1)
    |> reduce(:to_string)

  single_quoted =
    ignore(string("'"))
    |> repeat(utf8_char([{:not, ?'}]))
    |> reduce(:to_string)
    |> ignore(string("'"))

  double_quoted =
    ignore(string("\""))
    |> repeat(utf8_char([{:not, ?"}]))
    |> reduce(:to_string)
    |> ignore(string("\""))

  ipa =
    ignore(string("/"))
    |> reduce(repeat(utf8_char([{:not, ?/}])), :to_string)
    |> ignore(string("/"))
    |> unwrap_and_tag(:ipa)

  block =
    ignore(string("["))
    |> optional(space)
    |> parsec(:block_inner)
    |> repeat(parsec(:block_inner))
    |> reduce(:finalize_block)
    |> optional(space)
    |> ignore(string("]"))

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

  caption =
    ignore(string("("))
    |> reduce(repeat(utf8_char([{:not, ?)}])), :to_string)
    |> ignore(string(")"))

  modifier =
    caption
    |> choice([block, string("[]") |> reduce(:empty_block)])
    |> reduce(:finalize_modifier)

  section =
    ignore(string("#"))
    |> concat(block)
    |> optional(ignore(repeat(ascii_char([32]))))
    |> reduce(:finalize_section)

  mark =
    ignore(string("$["))
    |> concat(identifier)
    |> ignore(string("]"))
    |> unwrap_and_tag(:mark)

  audio =
    ignore(string("!"))
    |> optional(caption)
    |> ignore(string("["))
    |> choice([single_quoted, double_quoted])
    |> ignore(string("]"))
    |> reduce(:finalize_audio)

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
      parsec(:any_emphasis),
      empty()
    ])
    |> concat(
      choice([
        modifier,
        section,
        mark,
        audio,
        block,
        ws |> parsec(:any_emphasis),
        plaintext
      ])
      |> repeat()
    )
    |> reduce(:merge)
  )
end
