defmodule LambdaCalculus.Repl do
  def repl() do
    {:ok, pid} = LambdaCalculus.EvalServer.start_link([])
    read(pid, "")
  end

  defp read(server, previous) do
    did_read(server, previous, prompt!(previous == ""))
  end

  defp did_read(_server, <<>>, nil) do
    nil
  end

  defp did_read(server, previous, nil) do
    eval(server, previous, on_end_of_input: :give_up)
  end

  defp did_read(server, previous, <<>>) do
    case prompt!(previous == "") do
      <<>> -> did_read(server, previous, nil)
      line -> did_read(server, previous, line)
    end
  end

  defp did_read(server, previous, line) when is_binary(line) do
    eval(server, previous <> line <> " \n")
  end

  defp eval(server, text, opts \\ []) do
    on_eof = Keyword.get(opts, :on_end_of_input, :read_more)

    case LambdaCalculus.EvalServer.eval(server, text) do
      {:error, %Parsers.Error{unexpected: :end_of_input} = parser_error} ->
        case on_eof do
          :read_more -> read(server, text)
          _ -> print(server, :error, Parsers.Error.message(parser_error))
        end

      {:error, %Parsers.Error{} = parser_error} ->
        print(server, :error, Parsers.Error.message(parser_error))

      {ok_or_error, value} ->
        print(server, ok_or_error, inspect(value))
    end
  end

  defp print(server, :ok, value) do
    IO.puts(value)
    loop(server, "")
  end

  defp print(server, :error, error) do
    IO.puts(["ERROR: ", error])
    loop(server, "")
  end

  defp loop(server, text), do: read(server, text)

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
      :eof -> nil
      {:error, error} -> raise error
      data -> String.trim(data)
    end
  end
end
