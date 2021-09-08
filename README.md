# proXiMaL

[![Build Status](https://github.com/altenwald/proXiMaL/actions/workflows/elixir.yml/badge.svg)](https://github.com/altenwald/proXiMaL/actions/workflows/elixir.yml)
[![Coverage Status](https://coveralls.io/repos/github/altenwald/proXiMaL/badge.svg)](https://coveralls.io/github/altenwald/proXiMaL)
[![License: LGPL 2.1](https://img.shields.io/github/license/altenwald/proXiMaL.svg)](https://raw.githubusercontent.com/altenwald/proXiMaL/master/COPYING)
[![Hex](https://img.shields.io/hexpm/v/proXiMaL.svg)](https://hex.pm/packages/proXiMaL)

[Saxy]: https://github.com/qcam/saxy
[Nerves]: https://www.nerves-project.org/

proXiMaL is an advanced library for XML which let you to handle XML documents
is a better way thanks to the Elixir idioms implemented.

It's built on top of [Saxy] which is providing the needed mechanisms to perform
the parsing and building of the XML documents.

This library is 100% Elixir. No C, Rust or other language implementations are
needed so, it's eligible to be in use for [Nerves] and embedded systems.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `proximal` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:proximal, "~> 0.1.0"}
  ]
end
```
