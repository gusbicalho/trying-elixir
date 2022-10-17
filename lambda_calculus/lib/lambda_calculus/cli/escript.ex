defmodule LambdaCalculus.Cli.Escript do
  alias LambdaCalculus.Cli.System

  def main(_args \\ nil) do
    System.interact(:escript_repl)

    :ok
  end
end
