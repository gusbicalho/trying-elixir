defmodule Parsers.Grapheme do
  def any() do
    &any/1
  end

  def any(state) do
    case String.first(state.leftovers) do
      nil ->
        {state, {:error, "Unexpected end of input. Expected any grapheme."}}

      grapheme ->
        {state, {:ok, grapheme}}
    end
  end

  def matches(predicate, description \\ "grapheme matching predicate") do
    fn state ->
      case String.first(state.leftovers) do
        nil ->
          {state, {:error, ["Unexpected end of input. Expected ", description]}}

        grapheme ->
          if predicate.(grapheme) do
            {state, {:ok, grapheme}}
          else
            {state, {:error, ["Unexpected ", grapheme, ". Expected ", description]}}
          end
      end
    end
  end
end
