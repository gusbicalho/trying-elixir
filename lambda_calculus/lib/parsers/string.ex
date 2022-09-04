defmodule Parsers.String do
  alias Parsers.Internals.State

  def check(expected) do
    fn state ->
      {state, {:ok, String.starts_with?(state.leftovers, expected)}}
    end
  end

  def expect(expected) do
    fn state ->
      if String.starts_with?(state.leftovers, expected) do
        state = State.advance(state, String.length(expected))
        {state, {:ok, expected}}
      else
        {state,
         {:error,
          [
            "Expected ",
            expected,
            " but got ",
            String.slice(state.leftovers, 0, String.length(expected))
          ]}}
      end
    end
  end

  def many_graphemes_matching(predicate) do
    fn state ->
      advance = count_graphemes_matching(predicate, 0, state.leftovers)
      result = String.slice(state.leftovers, 0, advance)
      state = State.advance(state, advance)
      {state, {:ok, result}}
    end
  end

  def at_least_one_grapheme_matching(predicate, description \\ "grapheme matching predicate") do
    fn state ->
      advance = count_graphemes_matching(predicate, 0, state.leftovers)

      if advance == 0 do
        case String.next_grapheme(state.leftovers) do
          nil ->
            {state, {:error, ["Unexpected end of input. Expected at least one ", description]}}

          {grapheme, _} ->
            {state, {:error, ["Unexpected ", grapheme, ". Expected at least one ", description]}}
        end
      else
        result = String.slice(state.leftovers, 0, advance)
        state = State.advance(state, advance)
        {state, {:ok, result}}
      end
    end
  end

  defp count_graphemes_matching(predicate, found_so_far, leftovers) do
    case String.next_grapheme(leftovers) do
      nil ->
        found_so_far

      {grapheme, leftovers} ->
        if predicate.(grapheme) do
          count_graphemes_matching(predicate, found_so_far + 1, leftovers)
        else
          found_so_far
        end
    end
  end
end
