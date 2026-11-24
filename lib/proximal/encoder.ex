defmodule Proximal.Encoder do
  @moduledoc false

  alias Proximal.Prolog
  alias Proximal.Xmlel

  @doc """
  Encodes a `%Proximal.Xmlel{}` (or a struct implementing `Proximal`) directly
  into `iodata` in a single pass.
  """
  @spec encode_to_iodata(Xmlel.t() | struct(), Prolog.t() | keyword() | nil) :: iodata()
  def encode_to_iodata(root, prolog \\ nil)

  def encode_to_iodata(%Xmlel{} = root, prolog) do
    case prolog(prolog) do
      [] -> element(root)
      prolog_iodata -> [prolog_iodata | element(root)]
    end
  end

  def encode_to_iodata(%_{} = struct, prolog) do
    struct
    |> Proximal.to_xmlel()
    |> encode_to_iodata(prolog)
  end

  defp prolog(%Prolog{} = prolog) do
    [
      ~c"<?xml",
      version(prolog.version),
      encoding(prolog.encoding),
      standalone(prolog.standalone),
      ~c"?>"
    ]
  end

  defp prolog(prolog) when is_list(prolog) do
    prolog
    |> Prolog.from_keyword()
    |> prolog()
  end

  defp prolog(nil), do: []

  defp version(version) when is_binary(version) do
    [?\s, ~c"version", ?=, ?", version, ?"]
  end

  defp encoding(nil), do: []

  defp encoding(:utf8) do
    [?\s, ~c"encoding", ?=, ?", ~c"utf-8", ?"]
  end

  defp encoding(encoding) when encoding in ["UTF-8", "utf-8"] do
    [?\s, ~c"encoding", ?=, ?", encoding, ?"]
  end

  defp standalone(nil), do: []

  defp standalone(true) do
    [?\s, ~c"standalone", ?=, ?", "yes", ?"]
  end

  defp standalone(false) do
    [?\s, ~c"standalone", ?=, ?", "no", ?"]
  end

  defp element(%Xmlel{children: []} = xmlel) do
    [?<, tag_name(xmlel), namespaces(xmlel.namespaces), attributes(xmlel.attrs), ?/, ?>]
  end

  defp element(%Xmlel{children: children} = xmlel) do
    name = tag_name(xmlel)

    [
      ?<,
      name,
      namespaces(xmlel.namespaces),
      attributes(xmlel.attrs),
      ?>,
      content(children),
      ?<,
      ?/,
      name,
      ?>
    ]
  end

  defp tag_name(%Xmlel{schema: nil, name: name}), do: name
  defp tag_name(%Xmlel{schema: schema, name: name}), do: [schema, ?:, name]

  defp namespaces(ns) when map_size(ns) == 0, do: []

  defp namespaces(ns) do
    Enum.map(ns, fn {name, url} ->
      [?\s, "xmlns:", name, ?=, ?", escape(url, 0, url), ?"]
    end)
  end

  defp attributes(attrs) when map_size(attrs) == 0, do: []

  defp attributes(attrs) do
    Enum.map(attrs, fn
      {{ns, name}, value} ->
        [?\s, ns, ?:, name, ?=, ?", escape(value, 0, value), ?"]

      {name, value} ->
        [?\s, name, ?=, ?", escape(value, 0, value), ?"]
    end)
  end

  defp content([]), do: []

  defp content([chars | rest]) when is_binary(chars) do
    [escape(chars, 0, chars) | content(rest)]
  end

  defp content([%Xmlel{} = child | rest]) do
    [element(child) | content(rest)]
  end

  defp content([%_{} = struct | rest]) do
    [struct |> Proximal.to_xmlel() |> element() | content(rest)]
  end

  @escapes [
    {?<, ~c"&lt;"},
    {?>, ~c"&gt;"},
    {?&, ~c"&amp;"},
    {?", ~c"&quot;"},
    {?', ~c"&apos;"}
  ]

  for {match, insert} <- @escapes do
    defp escape(<<unquote(match), rest::bits>>, len, original) do
      [binary_part(original, 0, len), unquote(insert) | escape(rest, 0, rest)]
    end
  end

  defp escape(<<>>, _len, original) do
    original
  end

  defp escape(<<_, rest::bits>>, len, original) do
    escape(rest, len + 1, original)
  end
end
