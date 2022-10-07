defmodule LambdaCalculus.Repl do
  alias LambdaCalculus.EvalServer
  alias LambdaCalculus.Pipeline.Interpret.CompilationWarning
  alias LambdaCalculus.Pipeline.ParseTree.Node
  alias Parsers.Position

  def repl!() do
    {:ok, pid} = EvalServer.start_link()
    repl(pid)
  end

  def repl(server) do
    result = read_eval(server)

    if result do
      print(result)
      repl(server)
    end
  end

  defp read_eval(server) do
    go_read(server, "")
  end

  defp go_read(server, previous) do
    case prompt!(previous == "") do
      <<>> -> go_read(server, previous)
      nil when previous !== "" -> eval(server, previous, on_end_of_input: :give_up)
      nil -> nil
      line -> eval(server, previous <> line <> " \n")
    end
  end

  defp eval(server, text, opts \\ []) do
    on_eof = Keyword.get(opts, :on_end_of_input, :read_more)

    case EvalServer.eval(server, text) do
      {:error, %Parsers.Error{unexpected: :end_of_input}} when on_eof === :read_more ->
        go_read(server, text)

      {:error, %Parsers.Error{} = parser_error} ->
        {:error, Parsers.Error.message(parser_error)}

      # assume lists are chardata
      {:error, value} ->
        {:error,
         if is_binary(value) or is_list(value) do
           value
         else
           inspect(value)
         end}

      {:ok, value, warnings} ->
        {:ok, inspect(value), warnings}
    end
  end

  defp print({ok_or_error, value}) do
    print(ok_or_error, value, [])
  end

  defp print({ok_or_error, value, warnings}) do
    print(ok_or_error, value, warnings)
  end

  defp print(ok_or_error, value, warnings) do
    Enum.each(warnings, fn %CompilationWarning{message: message, node: node} ->
      IO.puts([
        "WARNING: ",
        message,
        case node do
          %Node{span: %Position.Span{start: %Position{line: line, column: column}}} ->
            [
              "\nat line ",
              to_string(line),
              ", column ",
              to_string(column)
            ]

          _ ->
            []
        end
      ])
    end)

    IO.puts([
      case ok_or_error do
        :ok -> []
        :error -> "ERROR: "
      end,
      value
    ])
  end

  defp prompt!(first_line?) do
    if first_line? do
      IO.write("> ")
    else
      IO.write("| ")
    end

    get_line!()
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
