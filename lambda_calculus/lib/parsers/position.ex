defmodule Parsers.Position do
  defstruct [:line, :column]

  def new(line, column) do
    %__MODULE__{line: line, column: column}
  end

  # def compare(
  #       %Parsers.Position{line: this_line, column: this_column},
  #       %Parsers.Position{line: that_line, column: that_column}
  #     ) do
  #   cond do
  #     this_line < that_line -> :lt
  #     this_line > that_line -> :gt
  #     this_column < that_column -> :lt
  #     this_column > that_column -> :gt
  #     :else -> :eq
  #   end
  # end

  # def max(p1, p2) do
  #   case compare(p1, p2) do
  #     :lt -> p2
  #     _ -> p1
  #   end
  # end

  # def min(p1, p2) do
  #   case compare(p1, p2) do
  #     :gt -> p2
  #     _ -> p1
  #   end
  # end

  defmodule Span do
    defstruct [:start, :end, :source_name]

    def new(%Parsers.Position{} = start, %Parsers.Position{} = end_, source_name \\ nil) do
      %__MODULE__{start: start, end: end_, source_name: source_name}
    end

    def extend(
          %__MODULE__{start: this_start, end: this_end, source_name: source_name},
          %__MODULE__{start: that_start, end: that_end}
        ) do
      %__MODULE__{
        start: min(this_start, that_start),
        end: max(this_end, that_end),
        source_name: source_name
      }
    end
  end
end
