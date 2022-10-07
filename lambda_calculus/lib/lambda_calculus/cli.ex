defmodule LambdaCalculus.Cli do
  use Bakeware.Script

  def main(_) do
    server_id = :wtf

    {:ok, _} =
      Supervisor.start_link(
        [
          LambdaCalculus.ProcessRegistry,
          {LambdaCalculus.EvalServer, server_id}
        ],
        strategy: :one_for_one
      )

    LambdaCalculus.Repl.repl(server_id)
    :ok
  end
end
