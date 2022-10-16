defmodule LambdaCalculus.Cli.Escript do
  alias LambdaCalculus.Cli.System

  def main(_args \\ nil) do
    System.start_link()
    name = :default_repl
    System.create_session(name)
    System.interact(name)

    :ok
  end
end
