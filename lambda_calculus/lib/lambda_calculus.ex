defmodule LambdaCalculus do
  @moduledoc """

  """

  def test_stmt(s) do
    {stmt, ""} = Parsers.run!(LambdaCalculus.Pipeline.Parser.stmt_parser(), s)
    stmt
  end

  def test do
    "\\ q -> plus q 1      "
    |> IO.inspect()
    |> test_stmt()
    |> IO.inspect()

    "let id = \\a -> a              "
    |> IO.inspect()
    |> test_stmt()
    |> IO.inspect()

    nil
  end
end
