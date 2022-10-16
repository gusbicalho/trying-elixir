defmodule LambdaCalculus.MixProject do
  use Mix.Project

  def project do
    [
      app: :lambda_calculus,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      compilers: [:boundary] ++ Mix.compilers(),
      escript: [main_module: LambdaCalculus.Cli.Escript],
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {LambdaCalculus.Cli, []},
      extra_applications: [:logger],
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:boundary, "~> 0.9.4", runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:freedom_formatter, ">= 2.0.0", runtime: false},
      {:typed_struct,
       git: "https://github.com/gusbicalho/typed_struct.git", ref: "a1e60cd9e66c07b168b8d457d65ae211cef4f0e5"},
    ]
  end
end
