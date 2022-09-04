defmodule LambdaCalculus do
  @moduledoc """

  """

  def test do
    {expr, ""} =
      Parsers.run!(
        LambdaCalculus.Pipeline.Parser.stmt_parser(),
        "\\ q -> plus q 1"
      )

    IO.inspect(expr)

    {decl, ""} =
      Parsers.run!(
        LambdaCalculus.Pipeline.Parser.stmt_parser(),
        "let id = \\a -> a"
      )

    IO.inspect(decl)
  end
end
