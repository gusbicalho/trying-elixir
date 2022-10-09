defmodule LambdaCalculus.ProcessRegistry do
  use Boundary

  def start_link() do
    %{start: {registry, function, args}} = child_spec(nil)
    apply(registry, function, args)
  end

  def child_spec(_) do
    Supervisor.child_spec(
      {Registry, [keys: :unique, name: __MODULE__]},
      []
    )
  end

  def via(name) do
    {:via, Registry, {__MODULE__, name}}
  end
end
