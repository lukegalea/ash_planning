defmodule AshPlanning.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/lukegalea/ash_planning"

  def project do
    [
      app: :ash_planning,
      version: @version,
      elixir: "~> 1.17",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description:
        "A constraint-solving proposal kernel for Ash: backends, IR, validators, resource fragments.",
      package: [
        licenses: ["MIT"],
        links: %{"GitHub" => @source_url},
        files: ~w(lib priv/boundary_markers.txt docs usage-rules.md README.md mix.exs)
      ],
      source_url: @source_url
    ]
  end

  def application, do: [extra_applications: [:logger]]

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:ash, "~> 3.0"},
      {:ash_open_lineage, github: "lukegalea/ash_open_lineage"},
      {:solverl, "~> 1.1", optional: true},
      {:jason, "~> 1.4"},
      {:decimal, "~> 2.1 or ~> 3.0"},
      {:sourceror, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end
end
