defmodule LambdaCalculus.Cli do
  alias LambdaCalculus.EvalServer
  alias LambdaCalculus.ProcessRegistry
  alias LambdaCalculus.ReplServer

  use Bakeware.Script

  def main(_ \\ nil) do
    start_link()
    interact()
    :ok
  end

  @default_repl :repl

  def start_link(repl_name \\ @default_repl) do
    server_id = String.to_atom(to_string(repl_name) <> ".EvalServer")

    Supervisor.start_link(
      [
        ProcessRegistry,
        {EvalServer, server_id},
        {ReplServer, {repl_name, server_id}}
      ],
      strategy: :one_for_one
    )
  end

  def interact(repl_name \\ @default_repl) do
    ReplServer.interact(repl_name, %{
      write: &IO.write/1,
      get_line: &get_line!/0
    })
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
          data -> data
        end
    end
  end
end
