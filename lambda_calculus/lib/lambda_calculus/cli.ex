defmodule LambdaCalculus.Cli do
  alias LambdaCalculus.Interpreter
  alias LambdaCalculus.ProcessRegistry
  alias LambdaCalculus.Repl

  def main(_args \\ nil) do
    name = :default_repl

    {:ok, _} = start_link(name) |> reuse_existing()

    Repl.interact(repl(name))

    :ok
  end

  def start_link(name) do
    interpreter = interpreter(name)

    Supervisor.start_link(
      [
        ProcessRegistry,
        {Interpreter,
         %{
           name: interpreter,
           built_ins: LambdaCalculus.BuiltIns.built_ins(),
         }},
        {Repl,
         %{
           name: repl(name),
           interpreter: interpreter,
         }},
      ],
      strategy: :one_for_one,
      name: via(name)
    )
  end

  def via(name), do: {:global, {__MODULE__, name}}
  def interpreter(name), do: {__MODULE__, name, :eval}
  def repl(name), do: {__MODULE__, name, :repl}

  def reuse_existing({:ok, _} = ok), do: ok
  def reuse_existing({:error, {:already_started, pid}}), do: {:ok, pid}
  def reuse_existing({:error, _} = error), do: error
end
