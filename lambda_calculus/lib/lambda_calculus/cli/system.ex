defmodule LambdaCalculus.Cli.System do
  alias LambdaCalculus.ProcessRegistry
  alias LambdaCalculus.Cli.Session

  def create_session(session_name \\ :default) do
    DynamicSupervisor.start_child(
      session_supervisor(),
      Session.child_spec(session(session_name))
    )
  end

  def interact(session_name \\ :default) do
    {:ok, _} = create_session(session_name) |> reuse_existing()
    Session.interact(session(session_name))
  end

  def interact_directly(session_name \\ :default) do
    {:ok, _} = create_session(session_name) |> reuse_existing()
    Session.interact_directly(session(session_name))
  end

  def child_spec(_) do
    %{id: __MODULE__, start: {__MODULE__, :start_link, []}}
  end

  def start_link() do
    children = [
      ProcessRegistry,
      {
        DynamicSupervisor,
        name: session_supervisor(), strategy: :one_for_one
      },
    ]

    opts = [
      strategy: :one_for_one,
      name: __MODULE__.Supervisor,
    ]

    Supervisor.start_link(children, opts)
  end

  defp session_supervisor(), do: ProcessRegistry.via({__MODULE__, :sessions})
  defp session(session_name), do: {__MODULE__, :session, session_name}

  defp reuse_existing({:ok, _} = ok), do: ok
  defp reuse_existing({:error, {:already_started, pid}}), do: {:ok, pid}
  defp reuse_existing({:error, _} = error), do: error
end
