defmodule LambdaCalculus.Repl do
  use Boundary,
    deps: [
      LambdaCalculus.Interpreter,
      LambdaCalculus.Pipeline,
      LambdaCalculus.ProcessRegistry,
    ]

  alias LambdaCalculus.ProcessRegistry
  alias LambdaCalculus.Repl.Server
  alias LambdaCalculus.Repl.Client

  def start_link(%{
        name: name,
        interpreter: eval_server,
      }) do
    Supervisor.start_link(
      [
        {Server, {repl_server(name), eval_server}},
        {Client, repl_client(name)},
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

  def repl_server(repl), do: {__MODULE__, repl, :repl_server}
  def repl_client(repl), do: {__MODULE__, repl, :repl}

  def interact(name) do
    Client.interact(
      repl_client(name),
      repl_server(name)
    )
  end
end
