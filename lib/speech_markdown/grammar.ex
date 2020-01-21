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
    with {:ok, [ast], _, _, _, _} <- document(text) do
      {:ok, ast}
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

  # --------------------------------------------------------------------------
  # breaks
  # --------------------------------------------------------------------------
  break =
    ignore(string("["))
    |> ignore(space)
    |> ignore(optional(string("break") |> optional(space) |> string(":")))
    |> ignore(space)
    |> integer(min: 1)
    |> choice([atomize.("ms"), atomize.("s")])
    |> ignore(space)
    |> ignore(string("]"))
    |> tag(:break)

  # --------------------------------------------------------------------------
  # ipa
  # --------------------------------------------------------------------------
  ipa_long =
    ignore(optional(string("ipa") |> optional(space) |> string(":")))
    |> ignore(space)
    |> ignore(string("\""))
    |> reduce(repeat(utf8_char([{:not, ?"}])), :to_string)
    |> ignore(string("\""))

  ipa_short =
    ignore(string("/"))
    |> reduce(repeat(utf8_char([{:not, ?/}])), :to_string)
    |> ignore(string("/"))

  ipa =
    choice([ipa_long, ipa_short])
    |> unwrap_and_tag(:ipa)

  # --------------------------------------------------------------------------
  # say-as
  # --------------------------------------------------------------------------
  say =
    choice([atomize.("characters"), atomize.("number")])
    |> unwrap_and_tag(:say)

  # --------------------------------------------------------------------------
  # all modifiers
  # --------------------------------------------------------------------------
  modifier =
    ignore(string("("))
    |> reduce(repeat(utf8_char([{:not, ?)}])), :to_string)
    |> ignore(string(")["))
    |> ignore(space)
    |> choice([ipa, say])
    |> ignore(space)
    |> ignore(string("]"))
    |> tag(:modifier)

  text =
    utf8_char([])
    |> reduce(:to_string)
    |> unwrap_and_tag(:text)

  defparsec(
    :document,
    choice([break, modifier, text])
    |> repeat()
    |> reduce(:merge)
  )
end
