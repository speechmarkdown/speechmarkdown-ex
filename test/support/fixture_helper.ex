defmodule SpeechMarkdown.TestSupport.FixtureHelper do
  @moduledoc false

  # Helper utilities for reading the test fixutres from the
  # speechmarkdown-test-files repository

  @base "#{__DIR__}/../fixtures/speechmarkdown-test-files/test-data/"

  alias SpeechMarkdown.TestSupport.XmlHelper

  @doc """
  Read a named fixture into a 4-tuple {smd, alexa, google, text}
  """
  def fixture(test) do
    base = @base <> test <> "/" <> test

    {
      File.read!(base <> ".smd"),
      File.read!(base <> ".alexa.ssml"),
      File.read!(base <> ".google.ssml"),
      File.read!(base <> ".txt") |> String.trim()
    }
  end

  @doc """
  Return the paths that are considered as reference test cases
  """
  def paths do
    Path.wildcard(@base <> "*") |> Enum.filter(&File.dir?/1)
  end

  @doc """
  XML assertion; generated XML might be semantically
  identical but different in string presentation; e.g. regarding
  ordering of element attributes.
  """
  defmacro assert_xml({:==, _, [a, b]}) do
    quote do
      if unquote(a) !== unquote(b) do
        parse_a = XmlHelper.parse(unquote(a))
        parse_b = XmlHelper.parse(unquote(b))

        assert parse_a === parse_b
      else
        assert unquote(a) === unquote(b)
      end
    end
  end
end
