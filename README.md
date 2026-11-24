<p align="center">
  <img src="assets/logo.svg" alt="Proximal Logo" width="160">
</p>

# Proximal

[![Hex Package](https://img.shields.io/hexpm/v/proximal.svg)](https://hex.pm/packages/proximal)
[![Hex Docs](https://img.shields.io/badge/hex-docs-purple.svg)](https://hexdocs.pm/proximal)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/altenwald/proximal/blob/main/LICENSE)
[![Build Status](https://github.com/altenwald/proximal/actions/workflows/elixir.yml/badge.svg)](https://github.com/altenwald/proximal/actions/workflows/elixir.yml)

> **proXiMaL** is an advanced XML library for Elixir with ergonomic structs,
> `Access` traversal, sigils, XML-RPC, and continuous streaming.

100% pure Elixir with **zero runtime dependencies** (`0-deps`). No C, Rust, or
external NIFs are required, making it ideal for standard BEAM applications as
well as [Nerves](https://www.nerves-project.org/) and embedded systems.

## Installation

Add `proximal` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:proximal, "~> 1.0"}
  ]
end
```

## Usage

### Parsing

Parse XML strings directly into `%Proximal.Xmlel{}` structs in a single pass,
or use the `~x` / `~X` sigils and `Access` behaviour:

```elixir
import Proximal.Xmlel, only: [sigil_x: 2]

{doc, _rest} = Proximal.Xmlel.parse(~s(<iq type="get" id="1"><query xmlns="urn:jabber:iq"/></iq>))

doc.name
#=> "iq"

Proximal.Xmlel.get_attr(doc, "type")
#=> "get"

# Access traversal
[query] = doc["query"]
query.attrs["xmlns"]
#=> "urn:jabber:iq"

# Sigil (~x strips whitespace-only text nodes, ~X preserves them)
stanza = ~x|<message to="alice@example.com"><body>Hello!</body></message>|
```

### Building and Serialization

Build XML elements with `Proximal.Xmlel.new/3` and serialize them in a single
pass to `iodata` with `to_iodata/1` or to binaries with `to_string/1`:

```elixir
alias Proximal.Xmlel

query = Xmlel.new("query", %{"xmlns" => "urn:jabber:iq"})
iq = Xmlel.new("iq", %{"type" => "get"}, [query])

Xmlel.to_iodata(iq)
#=> [60, "iq", [], [[32, "type", 61, 34, "get", 34]], 62, [...], 60, 47, "iq", 62]

to_string(iq)
#=> ~s(<iq type="get"><query xmlns="urn:jabber:iq"/></iq>)
```

You can also implement `Proximal.Document` on your own structs to render them
as `%Proximal.Xmlel{}` with `Proximal.to_xmlel/1`.

### Continuous Streaming

`Proximal.Stream` parses incoming chunks continuously and sends each completed
root element (`{:xmlelement, %Proximal.Xmlel{}}`) and stream event to the
target process without re-initializing the parser between stanzas:

```elixir
alias Proximal.Stream, as: XmlStream

{:ok, ""} =
  XmlStream.new(self())
  |> XmlStream.parse("<foo id='1'>Hello ")
  |> XmlStream.parse("world!</foo><bar/>")
  |> XmlStream.terminate()
```

## Benchmarks

Benchmarks run on macOS (Apple M1, 8 cores, 16 GB RAM, Elixir 1.20.4, Erlang/OTP 29.1.2, JIT enabled) using `elixir bench/benchmark.exs`.

Payloads: **Small** (133 B), **Medium** (9.7 KB, 100 items), **Large** (202.7 KB, 2,000 items).

### Parsing

| Library | Small (133 B) | Medium (9.7 KB) | Large (202.7 KB) | Memory (Large) |
| :--- | ---: | ---: | ---: | ---: |
| `Saxy.SimpleForm.parse_string/1` | 1.57 μs | 129.96 μs | 2.92 ms | 6.06 MB |
| `:erlsom.simple_form/1` | 1.93 μs | 221.29 μs | 4.12 ms | 18.72 MB |
| **`Proximal.Xmlel.parse/1`** | **3.68 μs** | **321.67 μs** | **6.69 ms** | **10.19 MB** |
| `SweetXml.parse/1` | 30.30 μs | 606.51 μs | 12.81 ms | 80.66 MB |
| `:xmerl_scan.string/1` | 21.34 μs | 619.96 μs | 13.01 ms | 81.35 MB |

> Note: `Proximal.Xmlel.parse/1` produces rich `%Proximal.Xmlel{}` structs with
> separated schemas, namespaces map, and `{ns, attr}` keys directly in one pass,
> while `Saxy.SimpleForm` and `:erlsom` produce raw tuple trees.

### Encoding / Serialization

| Library | Small (133 B) | Medium (9.7 KB) | Large (202.7 KB) | Memory (Large) |
| :--- | ---: | ---: | ---: | ---: |
| **`Proximal.Xmlel.to_iodata/1`** | **454 ns** | **36.27 μs** | **0.90 ms** | **2.69 MB** |
| `Saxy.encode!/1` (`iodata`) | 648 ns | 42.50 μs | 0.89 ms | 1.76 MB |
| `Proximal` `to_string/1` | 958 ns | 67.77 μs | 1.79 ms | 2.69 MB |
| `:xmerl.export_simple/2` | 1062 ns | 83.49 μs | 1.52 ms | 6.24 MB |

## Acknowledgements

Parts of the XML parser, streaming/partial engine, and encoder in Proximal are
derived from [Saxy](https://github.com/qcam/saxy) (MIT License). Special thanks
to [Cẩm Huỳnh (@qcam)](https://github.com/qcam) for creating and maintaining Saxy.

## License

MIT. See [LICENSE](LICENSE) for details (includes attribution for derived code from [Saxy](https://github.com/qcam/saxy)).
