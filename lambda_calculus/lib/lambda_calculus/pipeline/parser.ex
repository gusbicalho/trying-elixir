defmodule LambdaCalculus.Pipeline.Parser do
  alias Parsers, as: P

  def stmt_parser do
    P.alternatives([
      decl_parser() |> P.map(&{:decl, &1}),
      expr_parser() |> P.map(&{:expr, &1})
    ])
  end

  def decl_parser() do
    P.String.expect("let")
    |> P.also(P.Delimiter.whitespace1())
    |> P.then(identifier_parser())
    |> P.also(P.Delimiter.whitespace())
    |> P.also(P.String.expect("="))
    |> P.also(P.Delimiter.whitespace())
    |> P.paired_with(expr_parser())
    |> P.map(fn {identifier, definition} ->
      %{identifier: identifier, definition: definition}
    end)
  end

  def expr_parser do
    &expr_parser/1
  end

  def expr_parser(state) do
    P.alternatives([
      lambda_parser(),
      application_parser()
    ])
    |> then(& &1.(state))
  end

  def lambda_parser do
    P.String.expect("\\")
    |> P.also(P.Delimiter.whitespace())
    |> P.then(identifier_parser())
    |> P.also(P.Delimiter.whitespace())
    |> P.also(P.String.expect("->"))
    |> P.also(P.Delimiter.whitespace())
    |> P.paired_with(expr_parser())
    |> P.map(fn {param_id, body_expr} ->
      {:lambda, %{param: param_id, body: body_expr}}
    end)
  end

  def application_parser do
    P.at_least_one(application_sequence_item())
    |> P.paired_with(P.optional(lambda_parser()))
    |> P.map(fn {[app_head | app_args], trailing_lambda} ->
      app_args =
        if trailing_lambda do
          app_args ++ [trailing_lambda]
        else
          app_args
        end

      Enum.reduce(
        app_args,
        app_head,
        fn head, arg ->
          {:apply, %{function: head, argument: arg}}
        end
      )
    end)
  end

  def application_sequence_item do
    P.alternatives([
      parens(expr_parser()),
      identifier_parser() |> P.map(&%{lookup: &1}),
      Parsers.Numbers.integer() |> P.map(&%{literal: &1})
    ])
    |> P.also(P.Delimiter.whitespace())
  end

  def parens(parser) do
    P.String.expect("(")
    |> P.also(P.Delimiter.whitespace())
    |> P.then(parser)
    |> P.also(P.Delimiter.whitespace())
    |> P.also(P.String.expect(")"))
  end

  def identifier_parser do
    P.String.at_least_one_grapheme_matching(
      fn g ->
        Regex.match?(~r/[a-z]/, g)
      end,
      "lowercase letter"
    )
  end
end
