defmodule LambdaCalculus.Repl.Server do
  use GenServer

  # Client

  def prompt(id) do
    GenServer.call(via_tuple(id), :prompt)
  end

  def read_line(line, id) do
    GenServer.call(via_tuple(id), {:read_line, line})
  end

  def interact(id, %{write: write, get_line: get_line}) do
    do_while_truthy(fn ->
      write.(prompt(id))

      case get_line.() |> read_line(id) do
        nil -> nil
        "" -> :ok
        string -> write.([string, "\n"])
      end
    end)
  end

  defp do_while_truthy(f) do
    if f.() do
      do_while_truthy(f)
    end
  end

  # Process

  def start_link({id, eval_server_name}) do
    GenServer.start_link(__MODULE__, eval_server_name, name: via_tuple(id))
  end

  defp via_tuple(id) when is_pid(id) do
    id
  end

  defp via_tuple(id) do
    LambdaCalculus.ProcessRegistry.via({__MODULE__, id})
  end

  # Server (callbacks)

  alias LambdaCalculus.Interpreter
  alias LambdaCalculus.Pipeline.Interpret.CompilationWarning
  alias LambdaCalculus.Pipeline.ParseTree.Node
  alias Parsers.Position

  @impl true
  def init(eval_server_name) do
    {:ok, %{eval_server: eval_server_name, input: ""}}
  end

  @impl true
  def handle_call(:prompt, _from, %{input: input} = state) do
    prompt =
      if input === "" do
        "> "
      else
        "| "
      end

    {:reply, prompt, state}
  end

  @impl true
  def handle_call({:read_line, line}, _from, %{input: previous} = state) do
    case line do
      <<>> -> {:reply, "", state}
      nil when previous !== "" -> eval(state, previous, on_end_of_input: :give_up)
      nil -> {:stop, {:shutdown, :end_of_input}, nil, state}
      line -> eval(state, previous <> line <> " \n")
    end
  end

  defp eval(%{eval_server: server} = state, text, opts \\ []) do
    on_eof = Keyword.get(opts, :on_end_of_input, :read_more)

    {message, input_state} =
      case Interpreter.eval(server, text) do
        {:error, %Parsers.Error{unexpected: :end_of_input}} when on_eof === :read_more ->
          {"", text}

        {:error, value} ->
          message =
            case value do
              %Parsers.Error{} = parser_error -> Parsers.Error.message(parser_error)
              # assume lists are chardata
              value when is_binary(value) or is_list(value) -> value
              value -> inspect(value)
            end

          {print(:error, message), ""}

        {:ok, value, warnings} ->
          {print(:ok, inspect(value), warnings), ""}
      end

    {:reply, message, %{state | input: input_state}}
  end

  defp print(ok_or_error, value, warnings \\ []) do
    [
      Enum.map(warnings, fn %CompilationWarning{message: message, node: node} ->
        [
          "WARNING: ",
          message,
          case node do
            %Node{span: %Position.Span{start: %Position{line: line, column: column}}} ->
              [
                "\nat line ",
                to_string(line),
                ", column ",
                to_string(column),
              ]

            _ ->
              []
          end,
        ]
      end),
      [
        case ok_or_error do
          :ok -> []
          :error -> "ERROR: "
        end,
        value,
      ],
    ]
  end
end
