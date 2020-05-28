defmodule GraylogSearch.MixProject do
  use Mix.Project

  @version "1.0.1"

  def project do
    [
      app: :graylog_search,
      description: "Construct composable URLs for Graylog search queries",
      version: @version,
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      docs: docs()
    ]
  end

  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end

  defp package do
    [
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/dideler/graylog_search"}
    ]
  end

  defp docs do
    [
      extras: ["README.md": [title: "README"]],
      main: "GraylogSearch",
      source_ref: "v#{@version}",
      source_url: "https://github.com/dideler/graylog_search",
      canonical: "https://hexdocs.pm/graylog_search",
      groups_for_functions: [
        "API - Generic": &(&1[:group] == :generic),
        "API - Boolean operators": &(&1[:group] == :operators),
        "API - Time frames": &(&1[:group] == :time)
      ]
    ]
  end
end
