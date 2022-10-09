defmodule LambdaCalculus.Repl.Client do
  alias LambdaCalculus.Repl.Server

  def start_link(name) do
    Task.Supervisor.start_link(name: name)
  end

  def child_spec(name) do
    %{
      id: via_tuple(name),
      start: {__MODULE__, :start_link, [via_tuple(name)]},
    }
  end

  def interact(repl_name) do
    interact(repl_name, repl_name)
  end

  def interact(client_name, server_name) do
    Task.Supervisor.async_nolink(via_tuple(client_name), fn ->
      do_while_truthy(fn ->
        IO.write(Server.prompt(server_name))

        case get_line!() |> Server.read_line(server_name) do
          nil -> nil
          "" -> :ok
          string -> IO.write([string, "\n"])
        end
      end)
    end)
    |> Task.await(:infinity)
  end

  defp do_while_truthy(f) do
    if f.() do
      do_while_truthy(f)
    end
  end

  defp via_tuple(id) when is_pid(id) do
    id
  end

  defp via_tuple(id) do
    LambdaCalculus.ProcessRegistry.via({__MODULE__, id})
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
