defmodule LambdaCalculus.Repl.TaskSupervisor do
  def start_link(name) do
    Task.Supervisor.start_link(name: name)
  end

  def child_spec(name) do
    %{
      id: via(name),
      start: {__MODULE__, :start_link, [via(name)]},
    }
  end

  def via(id) when is_pid(id) do
    id
  end

  def via(id) do
    LambdaCalculus.ProcessRegistry.via({__MODULE__, id})
  end
end
