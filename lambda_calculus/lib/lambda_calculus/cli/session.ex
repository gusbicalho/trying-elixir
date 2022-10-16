defmodule LambdaCalculus.Cli.Session do
  alias LambdaCalculus.Interpreter
  alias LambdaCalculus.ProcessRegistry
  alias LambdaCalculus.Repl

  def child_spec(name) do
    %{id: __MODULE__, start: {__MODULE__, :start_link, [name]}}
  end

  def start_link(name) do
    children = children(name)
    supervisor_name = ProcessRegistry.via({__MODULE__, name, :supervisor})

    opts = [
      strategy: :one_for_one,
      name: supervisor_name,
    ]

    Supervisor.start_link(children, opts)
  end

  def interact(name \\ __MODULE__) do
    Repl.interact(repl(name))
  end

  def interact_directly(name \\ __MODULE__) do
    Repl.interact_directly(repl(name))
  end

  def children(name) do
    interpreter = interpreter(name)

    [
      {Task.Supervisor, name: task_supervisor(name)},
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
    ]
  end

  defp task_supervisor(name), do: ProcessRegistry.via({__MODULE__, name, :repl_server})
  defp interpreter(name), do: {__MODULE__, name, :eval}
  defp repl(name), do: {__MODULE__, name, :repl}
end
