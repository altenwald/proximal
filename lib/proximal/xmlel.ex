defmodule Proximal.Xmlel do
  @moduledoc """
  Xmlel is a struct data which is intended to help with the parsing
  of the XML elements.
  """

  alias Proximal.Xmlel

  @type attr_name :: String.t() | {String.t(), String.t()}
  @type attr_value :: String.t()
  @type attrs :: %{attr_name() => attr_value()}

  @typedoc """
  Xmlel.`t` defines the `xmlel` element which contains the `name`, the
  `attrs` (attributes) and `children` for the XML tags.
  """
  @type t() :: %__MODULE__{
          name: String.t(),
          full_name: String.t(),
          schema: String.t() | nil,
          namespaces: %{String.t() => String.t()},
          attrs: attrs(),
          children: [t() | String.t() | struct()]
        }
  @type children() :: [t] | [String.t()]

  defstruct name: nil,
            full_name: nil,
            schema: nil,
            namespaces: %{},
            attrs: %{},
            children: []

  @doc """
  Creates a Xmlel struct passing the `name` of the stanza, the `attrs`
  as a map or keyword list to create the attributes and `children` for
  the payload of the XML tag. This is not recursive so it's intended
  the children has to be in a correct format.

  The children could be or binaries (strings) representing CDATA or other
  `Proximal.Xmlel` elements.

  Examples:
      iex> Proximal.Xmlel.new("foo")
      %Proximal.Xmlel{full_name: "foo", attrs: %{}, children: [], name: "foo"}

      iex> Proximal.Xmlel.new("bar", %{"id" => "10"})
      %Proximal.Xmlel{full_name: "bar", attrs: %{"id" => "10"}, children: [], name: "bar"}

      iex> Proximal.Xmlel.new("bar", [{"id", "10"}])
      %Proximal.Xmlel{full_name: "bar", attrs: %{"id" => "10"}, children: [], name: "bar"}
  """
  @spec new(name :: String.t(), attrs() | [{attr_name(), attr_value()}], children()) :: t()
  def new(name, attrs \\ %{}, children \\ [])

  def new(name, attrs, children) when is_list(attrs) do
    new(name, Enum.into(attrs, %{}), children)
  end

  def new(full_name, attrs, children) when is_map(attrs) do
    {namespaces, attrs} =
      Enum.split_with(attrs, fn {key, _value} -> String.starts_with?(key, "xmlns:") end)

    attrs =
      Map.new(attrs, fn {name, value} ->
        case String.split(name, ":", parts: 2) do
          [ns, name] -> {{ns, name}, value}
          [name] -> {name, value}
        end
      end)

    namespaces =
      namespaces
      |> Enum.map(fn {"xmlns:" <> key, value} -> {key, value} end)
      |> Map.new()

    {schema, name} =
      case String.split(full_name, ":", parts: 2, trim: true) do
        [name] -> {nil, name}
        [schema, name] -> {schema, name}
      end

    %Xmlel{
      full_name: full_name,
      name: name,
      schema: schema,
      attrs: attrs,
      namespaces: namespaces,
      children: children
    }
  end

  @doc """
  Sigil to use ~X to provide XML `string` and transform it to Xmlel struct.
  Note that we are not using `addons`.

  Examples:
      iex> import Proximal.Xmlel
      iex> ~X|<foo>
      iex> </foo>
      iex> |
      %Proximal.Xmlel{attrs: %{}, children: ["\\n "], name: "foo", full_name: "foo"}
  """
  def sigil_X(string, _addons) do
    {xml, _rest} = parse(string)
    xml
  end

  @doc """
  Sigil to use ~x to provide XML `string` and transform it to Xmlel struct
  removing spaces and breaking lines.
  Note that we are not using `addons`.

  Examples:
      iex> import Proximal.Xmlel
      iex> ~x|<foo>
      iex> </foo>
      iex> |
      %Proximal.Xmlel{attrs: %{}, children: [], name: "foo", full_name: "foo"}
  """
  def sigil_x(string, _addons) do
    string
    |> parse()
    |> clean_spaces()
  end

  @doc """
  Parser a `xml` string into `Proximal.Xmlel` struct.

  Examples:
      iex> Proximal.Xmlel.parse("<foo/>")
      {%Proximal.Xmlel{full_name: "foo", name: "foo", attrs: %{}, children: []}, ""}

      iex> Proximal.Xmlel.parse("<foo bar='10'>hello world!</foo>")
      {%Proximal.Xmlel{full_name: "foo", name: "foo", attrs: %{"bar" => "10"}, children: ["hello world!"]}, ""}

      iex> Proximal.Xmlel.parse("<foo><bar>hello world!</bar></foo>")
      {%Proximal.Xmlel{full_name: "foo", name: "foo", attrs: %{}, children: [%Proximal.Xmlel{full_name: "bar", name: "bar", attrs: %{}, children: ["hello world!"]}]}, ""}

      iex> Proximal.Xmlel.parse("<foo/><bar/>")
      {%Proximal.Xmlel{full_name: "foo", name: "foo", attrs: %{}, children: []}, "<bar/>"}
  """
  def parse(xml) when is_binary(xml) do
    {:halt, [xmlel], more} = Saxy.parse_string(xml, Proximal.Handler.Simple, [])
    {decode(xmlel), more}
  end

  @doc """
  This function is a helper function to translate the tuples coming
  from Saxy into de `data` parameter to the `Proximal.Xmlel` structs.

  Examples:
      iex> Proximal.Xmlel.decode({"foo", [], []})
      %Proximal.Xmlel{full_name: "foo", name: "foo", attrs: %{}, children: []}

      iex> Proximal.Xmlel.decode({"foo", [], [{:characters, "1&1"}]})
      %Proximal.Xmlel{full_name: "foo", name: "foo", children: ["1&1"]}

      iex> Proximal.Xmlel.decode({"bar", [{"id", "10"}], ["Hello!"]})
      %Proximal.Xmlel{full_name: "bar", name: "bar", attrs: %{"id" => "10"}, children: ["Hello!"]}
  """
  def decode(data) when is_binary(data), do: data

  def decode({:characters, data}), do: data

  def decode(%Xmlel{attrs: attrs, children: children} = xmlel) do
    children = Enum.map(children, &decode/1)
    %Xmlel{xmlel | attrs: attrs, children: children}
  end

  def decode({name, attrs, children}) do
    new(name, attrs, children)
    |> decode()
  end

  @doc """
  This function is a helper function to translate the content of the
  `xmlel` structs to the tuples needed by Saxy.

  Examples:
      iex> Proximal.Xmlel.encode(%Proximal.Xmlel{name: "foo"})
      {"foo", [], []}

      iex> Proximal.Xmlel.encode(%Proximal.Xmlel{name: "bar", attrs: %{"id" => "10"}, children: ["Hello!"]})
      {"bar", [{"id", "10"}], [{:characters, "Hello!"}]}

      iex> Proximal.Xmlel.encode(%TestBuild{name: "bro"})
      {"bro", [], []}
  """
  def encode(%Xmlel{schema: nil} = xmlel) do
    children = Enum.map(xmlel.children, &encode/1)
    {xmlel.name, get_attrs(xmlel), children}
  end

  def encode(%Xmlel{} = xmlel) do
    children = Enum.map(xmlel.children, &encode/1)
    {"#{xmlel.schema}:#{xmlel.name}", get_attrs(xmlel), children}
  end

  def encode(content) when is_binary(content), do: {:characters, content}

  def encode(%_{} = struct) do
    struct
    |> Proximal.to_xmlel()
    |> encode()
  end

  defp get_attrs(%Xmlel{namespaces: ns, attrs: attrs}) do
    namespaces = Enum.map(ns, fn {name, url} -> {"xmlns:#{name}", url} end)

    attributes =
      Enum.map(attrs, fn
        {{ns, name}, value} -> {"#{ns}:#{name}", value}
        {name, value} -> {name, value}
      end)

    namespaces ++ attributes
  end

  defimpl String.Chars, for: __MODULE__ do
    alias Proximal.Xmlel
    alias Saxy.Builder
    alias Saxy.Encoder

    @doc """
    Implements `to_string/1` to convert a XML entity to a `xmlel`
    representation.

    Examples:
        iex> Proximal.Xmlel.new("foo") |> to_string()
        "<foo/>"

        iex> Proximal.Xmlel.new("bar", %{"id" => "10"}) |> to_string()
        "<bar id=\\"10\\"/>"

        iex> query = Proximal.Xmlel.new("query", %{"xmlns" => "urn:jabber:iq"})
        iex> Proximal.Xmlel.new("iq", %{"type" => "get"}, [query]) |> to_string()
        "<iq type=\\"get\\"><query xmlns=\\"urn:jabber:iq\\"/></iq>"

        iex> Proximal.Xmlel.new("query", %{}, ["<going >"]) |> to_string()
        "<query>&lt;going &gt;</query>"
    """
    def to_string(xmlel) do
      xmlel
      |> Xmlel.encode()
      |> Builder.build()
      |> Encoder.encode_to_iodata(nil)
      |> IO.chardata_to_string()
    end
  end

  defimpl Saxy.Builder, for: Xmlel do
    @moduledoc false
    @doc """
    Generates the Saxy tuples from `xmlel` structs.

    Examples:
        iex> Saxy.Builder.build(Proximal.Xmlel.new("foo", %{}, []))
        {"foo", [], []}
    """
    def build(xmlel) do
      Xmlel.encode(xmlel)
    end
  end

  @doc """
  Retrieve an attribute by `name` from a `xmlel` struct. If the value
  is not found the `default` value is used instead. If `default` is
  not provided then `nil` is used as default value.

  Examples:
      iex> attrs = %{"id" => "100", {"ns1", "name"} => "Alice"}
      iex> xmlel = %Proximal.Xmlel{attrs: attrs}
      iex> Proximal.Xmlel.get_attr(xmlel, "name")
      "Alice"
      iex> Proximal.Xmlel.get_attr(xmlel, "id")
      "100"
      iex> Proximal.Xmlel.get_attr(xmlel, "ns1:name")
      "Alice"
      iex> Proximal.Xmlel.get_attr(xmlel, "surname")
      nil
  """
  def get_attr(%Xmlel{attrs: attrs}, name, default \\ nil) do
    with [^name] <- String.split(name, ":", parts: 2),
         {:value, nil} <- {:value, Map.get(attrs, name)},
         [{_name, value} | _] <- filter_by_name(attrs, name) do
      value
    else
      {:value, value} -> value
      [ns, name] -> Map.get(attrs, {ns, name}, default)
      _ -> default
    end
  end

  defp filter_by_name(attrs, name) do
    Enum.filter(attrs, fn
      {{_ns, bare_name}, _value} -> bare_name == name
      {bare_name, _value} -> bare_name == name
    end)
  end

  @doc """
  Deletes an attribute by `name` from a `xmlel` struct.

  Examples:
      iex> attrs = %{"id" => "100", "name" => "Alice"}
      iex> xmlel = %Proximal.Xmlel{attrs: attrs}
      iex> Proximal.Xmlel.get_attr(xmlel, "name")
      "Alice"
      iex> Proximal.Xmlel.delete_attr(xmlel, "name")
      iex> |> Proximal.Xmlel.get_attr("name")
      nil
  """
  def delete_attr(%Xmlel{attrs: attrs} = xmlel, name) do
    %Xmlel{xmlel | attrs: Map.delete(attrs, name)}
  end

  @doc """
  Add or set a `value` by `name` as attribute inside of the `xmlel` struct
  passed as parameter.

  Examples:
      iex> attrs = %{"id" => "100", "name" => "Alice"}
      iex> %Proximal.Xmlel{attrs: attrs}
      iex> |> Proximal.Xmlel.put_attr("name", "Bob")
      iex> |> Proximal.Xmlel.get_attr("name")
      "Bob"
  """
  def put_attr(%Xmlel{attrs: attrs} = xmlel, name, value) do
    %Xmlel{xmlel | attrs: Map.put(attrs, name, value)}
  end

  @doc """
  Add or set one or several attributes using `fields` inside of the `xmlel`
  struct passed as parameter. The `fields` data are in keyword list format.

  Examples:
      iex> fields = %{"id" => "100", "name" => "Alice", "city" => "Cordoba"}
      iex> Proximal.Xmlel.put_attrs(%Proximal.Xmlel{name: "foo"}, fields) |> to_string()
      "<foo city=\\"Cordoba\\" id=\\"100\\" name=\\"Alice\\"/>"

      iex> fields = %{"id" => "100", "name" => "Alice", "city" => :"Cordoba"}
      iex> Proximal.Xmlel.put_attrs(%Proximal.Xmlel{name: "foo"}, fields) |> to_string()
      "<foo id=\\"100\\" name=\\"Alice\\"/>"
  """
  def put_attrs(xmlel, fields) do
    Enum.reduce(fields, xmlel, fn
      {_field, value}, acc when is_atom(value) -> acc
      {field, value}, acc -> put_attr(acc, field, value)
    end)
  end

  @doc """
  Provide the name of the children tags.

  Examples:
      iex> import Proximal.Xmlel, only: [sigil_x: 2]
      iex> xmlel = ~x[<root><child1/><child2/><child3/></root>]
      iex> Proximal.Xmlel.children_tag_names(xmlel)
      ["child1", "child2", "child3"]
  """
  def children_tag_names(%Xmlel{children: children}) do
    for %Xmlel{name: name} <- children do
      name
    end
    |> Enum.sort()
    |> Enum.uniq()
  end

  @doc """
  This function removes the extra spaces inside of the stanzas starting from
  `xmlel` to ensure we can perform matching in a proper way.

  Examples:
      iex> "<foo>\\n    <bar>\\n        Hello<br/>world!\\n    </bar>\\n</foo>"
      iex> |> Proximal.Xmlel.parse()
      iex> |> Proximal.Xmlel.clean_spaces()
      iex> |> to_string()
      "<foo><bar>Hello<br/>world!</bar></foo>"
  """
  def clean_spaces({xmlel, _rest}), do: clean_spaces(xmlel)

  def clean_spaces(%Xmlel{children: []} = xmlel), do: xmlel

  def clean_spaces(%Xmlel{children: children} = xmlel) do
    children =
      Enum.reduce(children, [], fn
        content, acc when is_binary(content) ->
          content = String.trim(content)
          if content != "", do: [content | acc], else: acc

        %Xmlel{} = x, acc ->
          [clean_spaces(x) | acc]
      end)
      |> Enum.reverse()

    %Xmlel{xmlel | children: children}
  end

  @behaviour Access

  defp split_children(children, name) do
    children
    |> Enum.reduce(
      %{match: [], nonmatch: []},
      fn
        %Xmlel{name: ^name} = el, acc ->
          %{acc | match: [el | acc.match]}

        el, acc ->
          %{acc | nonmatch: [el | acc.nonmatch]}
      end
    )
    |> Enum.map(fn {k, v} -> {k, Enum.reverse(v)} end)
    |> Enum.into(%{})
  end

  @impl Access
  @doc """
  Access the value stored under `key` passing the stanza in
  `Proximal.Xmlel` format into the `xmlel` parameter.

  Examples:
      iex> import Proximal.Xmlel
      iex> el = ~x(<foo><c1 v="1"/><c1 v="2"/><c2/></foo>)
      iex> fetch(el, "c1")
      {:ok, [%Proximal.Xmlel{attrs: %{"v" => "1"}, children: [], name: "c1", full_name: "c1"}, %Proximal.Xmlel{attrs: %{"v" => "2"}, children: [], name: "c1", full_name: "c1"}]}
      iex> fetch(el, "nonexistent")
      :error
  """
  def fetch(%Xmlel{children: children}, key) do
    %{match: values} = split_children(children, key)

    if Enum.empty?(values) do
      :error
    else
      {:ok, values}
    end
  end

  @impl Access
  @doc """
  Access the value under `key` and update it at the same time for the `xmlel`
  using the `function` passed as paramter.

  Examples:
      iex> import Proximal.Xmlel
      iex> el = ~x(<foo><c1 v="1"/><c1 v="2"/><c2/></foo>)
      iex> fun = fn els ->
      iex> values = Enum.map(els, fn %Proximal.Xmlel{attrs: %{"v" => v}} = el -> %Proximal.Xmlel{el | attrs: %{"v" => "v" <> v}} end)
      iex> {els, values}
      iex> end
      iex> get_and_update(el, "c1", fun)
      {[%Proximal.Xmlel{attrs: %{"v" => "1"}, children: [], name: "c1", full_name: "c1"}, %Proximal.Xmlel{attrs: %{"v" => "2"}, children: [], name: "c1", full_name: "c1"}], %Proximal.Xmlel{attrs: %{}, children: [%Proximal.Xmlel{attrs: %{"v" => "v1"}, children: [], name: "c1", full_name: "c1"}, %Proximal.Xmlel{attrs: %{"v" => "v2"}, children: [], name: "c1", full_name: "c1"}, %Proximal.Xmlel{attrs: %{}, children: [], name: "c2", full_name: "c2"}], name: "foo", full_name: "foo"}}
      iex> fun = fn _els -> :pop end
      iex> get_and_update(el, "c1", fun)
      {[%Proximal.Xmlel{attrs: %{"v" => "1"}, children: [], name: "c1", full_name: "c1"}, %Proximal.Xmlel{attrs: %{"v" => "2"}, children: [], name: "c1", full_name: "c1"}], %Proximal.Xmlel{attrs: %{}, children: [%Proximal.Xmlel{attrs: %{}, children: [], name: "c2", full_name: "c2"}], name: "foo", full_name: "foo"}}
  """
  def get_and_update(%Xmlel{children: children} = xmlel, key, function) do
    %{match: match, nonmatch: nonmatch} = split_children(children, key)

    case function.(if Enum.empty?(match), do: nil, else: match) do
      :pop ->
        {match, %Xmlel{xmlel | children: nonmatch}}

      {get_value, update_value} ->
        {get_value, %Xmlel{xmlel | children: update_value ++ nonmatch}}
    end
  end

  @impl Access
  @doc """
  Pop the value under `key` passed an `Proximal.Xmlel` struct as `element`.

  Examples:
      iex> import Proximal.Xmlel
      iex> el = ~x(<foo><c1 v="1"/><c1 v="2"/><c2/></foo>)
      iex> pop(el, "c1")
      {[%Proximal.Xmlel{attrs: %{"v" => "1"}, children: [], name: "c1", full_name: "c1"}, %Proximal.Xmlel{attrs: %{"v" => "2"}, children: [], name: "c1", full_name: "c1"}], %Proximal.Xmlel{attrs: %{}, children: [%Proximal.Xmlel{attrs: %{}, children: [], name: "c2", full_name: "c2"}], name: "foo", full_name: "foo"}}
      iex> pop(el, "nonexistent")
      {[], %Proximal.Xmlel{attrs: %{}, children: [%Proximal.Xmlel{attrs: %{"v" => "1"}, children: [], name: "c1", full_name: "c1"}, %Proximal.Xmlel{attrs: %{"v" => "2"}, children: [], name: "c1", full_name: "c1"}, %Proximal.Xmlel{attrs: %{}, children: [], name: "c2", full_name: "c2"}], name: "foo", full_name: "foo"}}
  """
  def pop(%Xmlel{children: children} = element, key) do
    case split_children(children, key) do
      %{match: []} ->
        {[], element}

      %{match: match, nonmatch: nonmatch} ->
        {match, %Xmlel{element | children: nonmatch}}
    end
  end
end
