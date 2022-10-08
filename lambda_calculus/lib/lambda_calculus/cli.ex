defmodule LambdaCalculus.Cli do
  alias LambdaCalculus.EvalState
  alias LambdaCalculus.EvalServer
  alias LambdaCalculus.ProcessRegistry
  alias LambdaCalculus.ReplServer
  alias LambdaCalculus.Cli.ReplClient

  use Bakeware.Script

  def main(_ \\ nil) do
    repl = :default_repl

    {:ok, _} = start_link(repl) |> reuse_existing()

    ReplClient.interact(
      repl_client(repl),
      repl_server(repl)
    )

    :ok
  end

  def start_link(repl) do
    eval_server = eval_server(repl)
    repl_client = repl_client(repl)

    Supervisor.start_link(
      [
        ProcessRegistry,
        {EvalState, {eval_server, LambdaCalculus.BuiltIns.built_ins()}},
        {EvalServer, eval_server},
        {ReplServer, {repl_server(repl), eval_server}},
        {ReplClient, repl_client},
      ],
      strategy: :one_for_one,
      name: {:global, {__MODULE__, repl}}
    )
  end

  def eval_server(repl), do: {__MODULE__, repl, :eval}
  def repl_server(repl), do: {__MODULE__, repl, :repl_server}
  def repl_client(repl), do: {__MODULE__, repl, :repl}

  def reuse_existing({:ok, _} = ok), do: ok
  def reuse_existing({:error, {:already_started, pid}}), do: {:ok, pid}
  def reuse_existing({:error, _} = error), do: error
end
