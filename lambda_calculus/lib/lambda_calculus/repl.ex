defmodule LambdaCalculus.Repl do
  def repl() do
    {:ok, pid} = LambdaCalculus.EvalServer.start_link([])
    read(pid, "")
  end

  defp read(server, previous) do
    case prompt!(previous == "") do
      <<>> -> read(server, previous)
      nil when previous !== "" -> eval(server, previous, on_end_of_input: :give_up)
      nil -> nil
      line -> eval(server, previous <> line <> " \n")
    end
  end

  defp eval(server, text, opts \\ []) do
    on_eof = Keyword.get(opts, :on_end_of_input, :read_more)

    case LambdaCalculus.EvalServer.eval(server, text) do
      {:error, %Parsers.Error{unexpected: :end_of_input}} when on_eof === :read_more ->
        read(server, text)

      {:error, %Parsers.Error{} = parser_error} ->
        print(server, :error, Parsers.Error.message(parser_error))

      # assume lists are chardata
      {ok_or_error, value} when is_binary(value) or is_list(value) ->
        print(server, ok_or_error, value)

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
