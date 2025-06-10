defmodule Proximal.MixProject do
  use Mix.Project

  def project do
    [
      app: :proximal,
      version: "0.2.3",
      description: "proXiMaL is an advanced library for XML on top of Saxy",
      elixir: "~> 1.11",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      consolidate_protocols: Mix.env() != :test,
      dialyzer: [plt_add_apps: [:mix]],
      deps: deps(),
      package: package(),
      docs: docs(),
      preferred_cli_env: [
        check: :test
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
      {:saxy, "~> 1.4"},

      # only for dev
      {:dialyxir, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:credo, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:doctor, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:ex_check, "~> 0.14", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:mix_audit, ">= 0.0.0", only: [:dev, :test], runtime: false}
    ]
  end

  defp package do
    [
      files: ~w[ lib mix.exs mix.lock README.md COPYING ],
      maintainers: ["Manuel Rubio"],
      licenses: ["MIT"],
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
