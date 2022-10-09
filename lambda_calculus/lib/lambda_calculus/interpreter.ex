defmodule LambdaCalculus.Interpreter do
  use Boundary,
    deps: [
      LambdaCalculus.Pipeline,
      LambdaCalculus.ProcessRegistry,
    ],
    exports: []

  alias LambdaCalculus.ProcessRegistry
  alias LambdaCalculus.Interpreter.State
  alias LambdaCalculus.Interpreter.EvalServer

  def start_link(%{
        name: name,
        built_ins: built_ins,
      }) do
    Supervisor.start_link(
      [
        {State, {name, built_ins}},
        {EvalServer, name},
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

  def eval(name, text) do
    EvalServer.eval(name, text)
  end
end
