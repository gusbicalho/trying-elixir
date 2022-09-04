defmodule Parsers.Internals do
  defmodule Position do
    defstruct [:line, :column]

    def new(line, column) do
      %__MODULE__{line: line, column: column}
    end
  end

  defmodule State do
    defstruct [:leftovers, :consumed_so_far, :position]

    def new(text) do
      %__MODULE__{
        leftovers: text,
        consumed_so_far: 0,
        position: Position.new(0, 0)
      }
    end

    def advance(state, distance) do
      {consumed, leftovers} = String.split_at(state.leftovers, distance)

      {current_line, current_col} =
        consumed
        |> String.replace(~r".*\n", "\n")
        |> String.split("\n")
        |> then(fn lines ->
          skipped_lines = Enum.count(lines) - 1
          latest_line = Enum.at(lines, -1)
          current_line = state.position.line + skipped_lines

          current_col =
            if skipped_lines == 0 do
              state.position.column + String.length(latest_line)
            else
              String.length(latest_line)
            end

          {current_line, current_col}
        end)

      %State{
        state
        | leftovers: leftovers,
          consumed_so_far: state.consumed_so_far + String.length(consumed),
          position: %Position{
            line: current_line,
            column: current_col
          }
      }
    end
  end
end
