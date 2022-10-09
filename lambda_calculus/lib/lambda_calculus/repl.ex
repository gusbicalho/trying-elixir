defmodule LambdaCalculus.Repl do
  use Boundary,
    deps: [
      LambdaCalculus.Interpreter,
      LambdaCalculus.Pipeline,
      LambdaCalculus.ProcessRegistry,
    ]

  alias LambdaCalculus.ProcessRegistry
  alias LambdaCalculus.Repl.Server
  alias LambdaCalculus.Repl.TaskSupervisor
  alias LambdaCalculus.Repl.Client

  def start_link(%{
        name: name,
        interpreter: eval_server,
      }) do
    task_supervisor = task_supervisor(name)
    repl_client = repl_client(name)
    repl_server = repl_server(name)

    Supervisor.start_link(
      [
        {TaskSupervisor, task_supervisor},
        {Server, {repl_server, eval_server}},
        {Client,
         %{
           name: repl_client,
           server: repl_server,
           task_supervisor: TaskSupervisor.via(task_supervisor),
         }},
      ],
      strategy: :one_for_one,
      name: ProcessRegistry.via({__MODULE__, name})
    )
  end

  def child_spec(%{name: name} = arg) do
    %{
      id: {__MODULE__, name},
      type: :supervisor,
      start: {__MODULE__, :start_link, [arg]},
    }
  end

  defp task_supervisor(name), do: {__MODULE__, name, :repl_server}
  defp repl_server(name), do: {__MODULE__, name, :repl_server}
  defp repl_client(name), do: {__MODULE__, name, :repl}

  @doc """
  Runs a REPL interactive loop in the console, blocking the calling
  process until the REPL is exited normally.
  """
  def interact(name) do
    Client.interact(repl_client(name))
  end
end
