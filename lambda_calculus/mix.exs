defmodule LambdaCalculus.MixProject do
  use Mix.Project

  def project do
    [
      app: :lambda_calculus,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      compilers:
        concat_all([
          # Workaround to avoid Boundary breaking ElixirLS:
          # ElixirLS runs with the ELS_MODE env var set, so we disable the
          # Boundary compiler in that case.
          # See https://github.com/elixir-lsp/elixir-ls/issues/717
          if !System.get_env("ELS_MODE") do
            [:boundary]
          end,
          Mix.compilers()
        ])
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  def concat_all(lists) do
    Enum.flat_map(lists, fn
      nil -> []
      list -> list
    end)
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:boundary, "~> 0.9", runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:typed_struct, git: "https://github.com/Liveflow-io/typed_struct.git", ref: "5234d25"}
    ]
  end
end
