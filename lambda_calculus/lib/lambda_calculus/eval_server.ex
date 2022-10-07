defmodule LambdaCalculus.EvalServer do
  use GenServer

  # Client

  def eval(id, text) do
    GenServer.call(via_tuple(id), {:eval, text})
  end

  # Process

  def start_link() do
    GenServer.start_link(__MODULE__, nil)
  end

  def start_link(id) do
    case GenServer.start_link(__MODULE__, id, name: via_tuple(id)) do
      {:error, {:already_started, pid}} -> {:ok, pid}
      other -> other
    end
  end

  defp via_tuple(id) when is_pid(id) do
    id
  end

  defp via_tuple(id) do
    LambdaCalculus.ProcessRegistry.via({__MODULE__, id})
  end

  # Server (callbacks)

  alias LambdaCalculus.Pipeline
  alias LambdaCalculus.EvalState

  @impl true
  def init(state_id) do
    {:ok, state_id}
  end

  @impl true
  def handle_call({:eval, text}, _from, state_id) do
    with {parse_result, leftovers} <- Pipeline.TextToParseTree.parse_stmt(text),
         {:ok, stmt} <- parse_result,
         nil <-
           (if leftovers !== "" do
              {:error, ["unexpected ", leftovers]}
            end),
         {:ok, stmt} <- Pipeline.ParseTreeToAST.Statement.parse(stmt),
         stmt = Pipeline.ASTAnalysis.Scope.analyze(stmt),
         {:ok, {new_bindings, result, warnings}} <-
           Pipeline.Interpret.interpret_statement(
             EvalState.get_globals(state_id),
             stmt
           ) do
      EvalState.define_globals(state_id, new_bindings)
      {:reply, {:ok, result, warnings}, state_id}
    else
      error -> {:reply, error, state_id}
    end
  end
end
