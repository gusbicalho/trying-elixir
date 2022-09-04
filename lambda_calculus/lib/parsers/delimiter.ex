defmodule Parsers.Delimiter do
  alias Parsers.Internals.State

  def expect_end() do
    &expect_end/1
  end

  def expect_end(state) do
    case String.next_grapheme(state.leftovers) do
      nil ->
        {state, {:ok, nil}}

      {grapheme, _} ->
        {state,
         {:error,
          [
            "Expected end of input, but found ",
            grapheme
          ]}}
    end
  end

  def whitespace() do
    &whitespace/1
  end

  def whitespace(state) do
    whitespace_count =
      String.length(state.leftovers) - String.length(String.trim_leading(state.leftovers))

    {State.advance(state, whitespace_count), {:ok, nil}}
  end

  def whitespace1() do
    &whitespace1/1
  end

  def whitespace1(state) do
    whitespace_count =
      String.length(state.leftovers) - String.length(String.trim_leading(state.leftovers))

    if whitespace_count > 0 do
      {State.advance(state, whitespace_count), {:ok, nil}}
    else
      case String.next_grapheme(state.leftovers) do
        nil ->
          {state, {:error, "Expected whitespace, got end of input"}}

        {g, _} ->
          {state, {:error, ["Expected whitespace, got ", g]}}
      end
    end
  end
end
