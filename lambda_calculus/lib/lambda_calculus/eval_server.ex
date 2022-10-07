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
    case GenServer.start_link(__MODULE__, nil, name: via_tuple(id)) do
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

  @impl true
  def init(_) do
    {:ok, %{plus: &plus/2, repeatedly: &repeatedly/2}}
  end

  @impl true
  def handle_call({:eval, text}, _from, global_env) do
    with {parse_result, leftovers} <- Pipeline.TextToParseTree.parse_stmt(text),
         {:ok, stmt} <- parse_result,
         nil <-
           (if leftovers !== "" do
              {:error, ["unexpected ", leftovers]}
            end),
         {:ok, stmt} <- Pipeline.ParseTreeToAST.Statement.parse(stmt),
         stmt = Pipeline.ASTAnalysis.Scope.analyze(stmt),
         {:ok, {global_env, result, warnings}} <- Pipeline.Interpret.interpret_statement(global_env, stmt) do
      {:reply, {:ok, result, warnings}, global_env}
    else
      error -> {:reply, error, global_env}
    end
  end

  # Native functions
  def plus(_global_env, v1) do
    fn _, v2 -> v1 + v2 end
  end

  def repeatedly(_global_env, num_times) do
    fn _, f ->
      fn global_env, arg ->
        go_repeatedly(num_times, f, global_env, arg)
      end
    end
  end

  def go_repeatedly(times_left, f, global_env, arg) when is_integer(times_left) and times_left > 0 do
    go_repeatedly(times_left - 1, f, global_env, f.(global_env, arg))
  end

  def go_repeatedly(_, _, _, arg) do
    arg
  end
end
