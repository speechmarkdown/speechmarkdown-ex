defmodule SpeechMarkdown.TestSupport.XmlHelper do
  @moduledoc false

  # This module parses XML from xmerl into a normalized form, in order
  # to compare XML strings that only differ on leading/trailing
  # whitespace and attribute order.

  require Record

  def parse(string) do
    {doc, []} =
      string
      |> :binary.bin_to_list()
      |> :xmerl_scan.string(quiet: true)

    simple_element(doc)
  end

  Record.defrecord(
    :xmlAttribute,
    Record.extract(:xmlAttribute, from_lib: "xmerl/include/xmerl.hrl")
  )

  Record.defrecord(
    :xmlText,
    Record.extract(:xmlText, from_lib: "xmerl/include/xmerl.hrl")
  )

  Record.defrecord(
    :xmlPI,
    Record.extract(:xmlPI, from_lib: "xmerl/include/xmerl.hrl")
  )

  Record.defrecord(
    :xmlComment,
    Record.extract(:xmlComment, from_lib: "xmerl/include/xmerl.hrl")
  )

  Record.defrecord(
    :xmlElement,
    Record.extract(:xmlElement, from_lib: "xmerl/include/xmerl.hrl")
  )

  def simple_element(xmlComment()) do
    :skip
  end

  def simple_element(xmlPI()) do
    :skip
  end

  def simple_element(xmlText(value: value)) do
    case IO.chardata_to_string(value) |> String.trim() do
      "" -> :skip
      text -> text
    end
  end

  def simple_element(xmlAttribute(value: value)) do
    if is_integer(value) or is_atom(value) do
      value
    else
      IO.chardata_to_string(value)
    end
  end

  def simple_element(
        xmlElement(name: name, attributes: attributes, content: content)
      ) do
    [to_string(name), simple_attributes(attributes), simple_content(content)]
  end

  def simple_attributes(attributes) do
    attributes
    |> Enum.map(fn xmlAttribute(name: name, value: value) ->
      {to_string(name), to_string(value)}
    end)
    |> Map.new()
  end

  def simple_content([xmlText(value: _value) = elem]) do
    simple_element(elem)
  end

  def simple_content(children) do
    children
    |> Enum.reduce([], &simple_content_reducer/2)
    |> Enum.reverse()
  end

  defp simple_content_reducer([xmlText() = child], acc) do
    # xmerl weirdness: sometimes, a child element contains a nested list
    simple_content_reducer(child, acc)
  end

  defp simple_content_reducer(child, acc) do
    case simple_element(child) do
      :skip -> acc
      result -> [result | acc]
    end
  end
end
