defmodule Proximal.MixProject do
  use Mix.Project

  def project do
    [
      app: :proximal,
      version: "1.0.1",
      description: "proXiMaL is an advanced 100% Elixir, zero-dependency XML library",
      elixir: "~> 1.11",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      consolidate_protocols: Mix.env() != :test,
      deps: deps(),
      package: package(),
      docs: docs(),
      aliases: aliases(),
      test_coverage: [
        ignore_modules: [
          Proximal.BufferingHelper,
          Proximal.Document,
          Proximal.Guards,
          Proximal.Parser.Builder,
          Proximal.Parser.Lookahead
        ]
      ]
    ]
  end

  def cli do
    [
      preferred_envs: [
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
      # only for dev/test
      {:prisma, "~> 0.2", only: [:dev, :test], runtime: false},
      {:credo, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:doctor, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:ex_check, "~> 0.14", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:mix_audit, ">= 0.0.0", only: [:dev, :test], runtime: false}
    ]
  end

  defp package do
    [
      files: ~w[ lib mix.exs mix.lock README.md LICENSE proximal_*.pplt ],
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
      logo: "assets/logo.svg",
      assets: %{"assets" => "assets"},
      extras: ["README.md", "LICENSE"]
    ]
  end

  defp aliases do
    [
      publish: ["prisma.build", "hex.publish"]
    ]
  end
end
