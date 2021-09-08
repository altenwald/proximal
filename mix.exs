defmodule Proximal.MixProject do
  use Mix.Project

  def project do
    [
      app: :proximal,
      version: "0.1.0",
      elixir: "~> 1.10",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      consolidate_protocols: Mix.env() != :test,
      dialyzer: [plt_add_apps: [:mix]],
      deps: deps(),
      aliases: aliases(),
      package: package(),
      docs: docs(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.json": :test,
        "coveralls.html": :test,
        "coveralls.post": :test,
        "coveralls.github": :test,
        actions: :test
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:saxy, "~> 1.4.0"},
      {:ex_doc, ">= 0.0.0", optional: true, only: :dev},
      {:dialyxir, "~> 1.0", optional: true, only: :dev, runtime: false},
      {:excoveralls, "~> 0.14", optional: true, only: :test}
    ]
  end

  defp aliases do
    [
      actions: [
        "local.hex --force",
        "local.rebar --force",
        "deps.get",
        "coveralls.github"
      ]
    ]
  end

  defp package do
    [
      files: ~w[ lib mix.exs mix.lock README.md COPYING ],
      maintainers: ["Manuel Rubio"],
      licenses: ["LGPL 2.1"],
      links: %{
        "GitHub" => "https://github.com/altenwald/proximal"
      }
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"]
    ]
  end
end
