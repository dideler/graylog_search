# 🔍 GraylogSearch

[![Hex pm](http://img.shields.io/hexpm/v/graylog_search.svg?style=flat)](https://hex.pm/packages/graylog_search)

A fun little library to programmatically create basic Graylog search URLs.

An example use case is chat alerts that link to logged events around failures.

Tested with Graylog v2.4.6 and v3.0.1. Not guaranteed to be compatible with other versions.

## Installation

The package can be installed by adding `graylog_search` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:graylog_search, "~> 1.0"}
  ]
end
```

## Usage

See examples in the docs at [https://hexdocs.pm/graylog_search](https://hexdocs.pm/graylog_search)
and [in the tests](test/graylog_search_test.exs).