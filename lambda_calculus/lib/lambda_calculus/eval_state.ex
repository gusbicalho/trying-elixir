defmodule LambdaCalculus.EvalState do
  use Agent

  def start_link({id, built_ins}) do
    case Agent.start_link(fn -> %{globals: built_ins} end, name: via_tuple(id)) do
      {:error, {:already_started, pid}} -> {:ok, pid}
      other -> other
    end
  end

  defp via_tuple(id) do
    case id do
      nil -> nil
      id when is_pid(id) -> id
      id -> LambdaCalculus.ProcessRegistry.via({__MODULE__, id})
    end
  end

  alias LambdaCalculus.Pipeline.Runtime

  def get_globals(id) do
    Agent.get(via_tuple(id), & &1.globals)
  end

  @spec define_globals(any(), Keyword.t(Runtime.value())) :: :ok
  def define_globals(id, new_bindings) do
    Agent.update(via_tuple(id), fn state ->
      update_in(state.globals, &Enum.into(new_bindings, &1))
    end)
  end
end
