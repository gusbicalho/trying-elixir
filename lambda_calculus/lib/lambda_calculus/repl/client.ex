defmodule LambdaCalculus.Repl.Client do
  use GenServer

  alias LambdaCalculus.Repl.Server

  # Client

  def interact(name) do
    GenServer.call(via_tuple(name), :interact, :infinity)
  end

  def interact_directly(repl_server) do
    do_interact(repl_server)
  end

  # Process

  def start_link(%{
        name: name,
        server: repl_server,
        task_supervisor: task_supervisor,
      }) do
    GenServer.start_link(
      __MODULE__,
      %{
        server: repl_server,
        task_supervisor: task_supervisor,
      },
      name: via_tuple(name)
    )
  end

  defp via_tuple(id) when is_pid(id) do
    id
  end

  defp via_tuple(id) do
    LambdaCalculus.ProcessRegistry.via({__MODULE__, id})
  end

  # Callbacks

  @impl true
  def init(config) do
    {:ok, Map.update(config, :running, nil, fn _ -> nil end)}
  end

  @impl true
  def handle_call(:interact, _from, %{running: %{}} = state) do
    {:reply, {:error, :busy}, state}
  end

  def handle_call(
        :interact,
        from,
        %{
          server: repl_server,
          task_supervisor: task_supervisor,
          running: nil,
        } = state
      ) do
    ref = start_interact(task_supervisor, repl_server)

    {:noreply,
     %{
       state
       | running: %{
           ref: ref,
           restart: fn -> start_interact(task_supervisor, repl_server) end,
           on_success: fn -> GenServer.reply(from, :ok) end,
         },
     }}
  end

  @impl true
  def handle_info({ref, _result}, %{running: %{ref: ref, on_success: on_success}} = state) do
    # The task is done.
    # No need to continue to monitor
    Process.demonitor(ref, [:flush])
    on_success.()
    {:noreply, %{state | running: nil}}
  end

  # Unexpected failure
  def handle_info(
        {:DOWN, ref, :process, _pid, _reason},
        %{running: %{ref: ref, restart: restart}} = state
      ) do
    # restart the task
    ref = restart.()
    {:noreply, put_in(state.running.ref, ref)}
  end

  # Interaction impl

  defp start_interact(task_supervisor, repl_server) do
    %{ref: ref} =
      Task.Supervisor.async_nolink(
        task_supervisor,
        fn -> do_interact(repl_server) end
      )

    ref
  end

  defp do_interact(repl_server) do
    do_while_truthy(fn ->
      IO.write(Server.prompt(repl_server))

      case get_line!() |> Server.read_line(repl_server) do
        nil -> nil
        "" -> :ok
        string -> IO.write([string, "\n"])
      end
    end)
  end

  defp do_while_truthy(f) do
    if f.() do
      do_while_truthy(f)
    end
  end

  defp get_line!() do
    case IO.read(:line) do
      {:error, error} ->
        raise error

      :eof ->
        nil

      data ->
        case String.trim(data) do
          ":q" -> nil
          ":!" -> raise "!!!"
          data -> data
        end
    end
  end
end
