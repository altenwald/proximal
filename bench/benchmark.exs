Mix.install([
  {:proximal, path: Path.expand("..", __DIR__)},
  {:saxy, "~> 1.6"},
  {:sweet_xml, "~> 0.7"},
  {:erlsom, "~> 1.5"},
  {:benchee, "~> 1.3"}
])

defmodule BenchData do
  def build_xml(count) do
    items =
      for i <- 1..count do
        ~s(<item id="#{i}" ns:type="entry" active="true"><title>Item &amp; #{i}</title><value>#{i * 10}</value></item>)
      end

    ~s(<feed xmlns:ns="urn:example:ns">#{IO.iodata_to_binary(items)}</feed>)
  end

  def to_xmerl_simple(%Proximal.Xmlel{name: name, schema: schema, namespaces: ns, attrs: attrs, children: children}) do
    tag =
      case schema do
        nil -> String.to_atom(name)
        s -> String.to_atom("#{s}:#{name}")
      end

    ns_attrs = Enum.map(ns, fn {k, v} -> {String.to_atom("xmlns:#{k}"), String.to_charlist(v)} end)

    plain_attrs =
      Enum.map(attrs, fn
        {{s, k}, v} -> {String.to_atom("#{s}:#{k}"), String.to_charlist(v)}
        {k, v} -> {String.to_atom(k), String.to_charlist(v)}
      end)

    xmerl_children =
      Enum.map(children, fn
        c when is_binary(c) -> String.to_charlist(c)
        %Proximal.Xmlel{} = c -> to_xmerl_simple(c)
      end)

    {tag, ns_attrs ++ plain_attrs, xmerl_children}
  end

  def to_saxy_simple(%Proximal.Xmlel{name: name, schema: schema, namespaces: ns, attrs: attrs, children: children}) do
    tag = if schema, do: "#{schema}:#{name}", else: name
    ns_attrs = Enum.map(ns, fn {k, v} -> {"xmlns:#{k}", v} end)

    plain_attrs =
      Enum.map(attrs, fn
        {{s, k}, v} -> {"#{s}:#{k}", v}
        {k, v} -> {k, v}
      end)

    saxy_children =
      Enum.map(children, fn
        c when is_binary(c) -> c
        %Proximal.Xmlel{} = c -> to_saxy_simple(c)
      end)

    {tag, ns_attrs ++ plain_attrs, saxy_children}
  end
end

small_xml = BenchData.build_xml(1)
medium_xml = BenchData.build_xml(100)
large_xml = BenchData.build_xml(2_000)

IO.puts("Payload sizes: small=#{byte_size(small_xml)}B, medium=#{byte_size(medium_xml)}B, large=#{byte_size(large_xml)}B")

IO.puts("\n=== PARSING BENCHMARK ===")

Benchee.run(
  %{
    "Proximal.Xmlel.parse/1" => fn xml -> Proximal.Xmlel.parse(xml) end,
    "Saxy.SimpleForm.parse_string/1" => fn xml -> Saxy.SimpleForm.parse_string(xml) end,
    "SweetXml.parse/1" => fn xml -> SweetXml.parse(xml, quiet: true) end,
    ":xmerl_scan.string/1" => fn xml ->
      {doc, _} = :xmerl_scan.string(String.to_charlist(xml), quiet: true)
      doc
    end,
    ":erlsom.simple_form/1" => fn xml -> :erlsom.simple_form(xml) end
  },
  inputs: %{
    "Small (~200B)" => small_xml,
    "Medium (~12KB)" => medium_xml,
    "Large (~240KB)" => large_xml
  },
  warmup: 1,
  time: 3,
  memory_time: 1
)

{small_xmlel, ""} = Proximal.Xmlel.parse(small_xml)
{medium_xmlel, ""} = Proximal.Xmlel.parse(medium_xml)
{large_xmlel, ""} = Proximal.Xmlel.parse(large_xml)

small_saxy = BenchData.to_saxy_simple(small_xmlel)
medium_saxy = BenchData.to_saxy_simple(medium_xmlel)
large_saxy = BenchData.to_saxy_simple(large_xmlel)

small_xmerl = [BenchData.to_xmerl_simple(small_xmlel)]
medium_xmerl = [BenchData.to_xmerl_simple(medium_xmlel)]
large_xmerl = [BenchData.to_xmerl_simple(large_xmlel)]

IO.puts("\n=== ENCODING / SERIALIZATION BENCHMARK ===")

Benchee.run(
  %{
    "Proximal.Xmlel.to_iodata/1" => fn {xmlel, _, _} -> Proximal.Xmlel.to_iodata(xmlel) end,
    "Proximal to_string/1" => fn {xmlel, _, _} -> to_string(xmlel) end,
    "Saxy.encode!/1" => fn {_, saxy, _} -> Saxy.encode!(saxy) end,
    ":xmerl.export_simple/2" => fn {_, _, xmerl} -> :xmerl.export_simple(xmerl, :xmerl_xml) end
  },
  inputs: %{
    "Small (~200B)" => {small_xmlel, small_saxy, small_xmerl},
    "Medium (~12KB)" => {medium_xmlel, medium_saxy, medium_xmerl},
    "Large (~240KB)" => {large_xmlel, large_saxy, large_xmerl}
  },
  warmup: 1,
  time: 3,
  memory_time: 1
)
