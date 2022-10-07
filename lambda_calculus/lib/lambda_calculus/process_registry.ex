defmodule LambdaCalculus.ProcessRegistry do
  def start_link() do
    case Registry.start_link(keys: :unique, name: __MODULE__) do
      {:error, {:already_started, pid}} -> {:ok, pid}
      other -> other
    end
  end

  def child_spec(_) do
    Supervisor.child_spec(
      Registry,
      id: __MODULE__,
      start: {__MODULE__, :start_link, []}
    )
  end

  def via(name) do
    {:via, Registry, {__MODULE__, name}}
  end
end
