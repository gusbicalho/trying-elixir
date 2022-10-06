defmodule LambdaCalculus.Cli do
  use Bakeware.Script

  def main(_) do
    LambdaCalculus.Repl.repl()
    :ok
  end
end
