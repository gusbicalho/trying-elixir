defmodule LambdaCalculus.Pipeline.TextToParseTree do
  alias Parsers, as: P
  alias LambdaCalculus.Pipeline.ParseTree, as: PTree
  alias LambdaCalculus.Pipeline.ParseTree.Node

  @spec parse_stmt(binary, Keyword.t()) :: {P.parser_return(Node.t()), binary}
  def parse_stmt(source, opts \\ []) do
    P.run(stmt_parser(), source, opts)
  end

  @spec stmt_parser :: P.parser(Node.t())
  def stmt_parser do
    P.alternatives([
      decl_parser(),
      expr_parser()
    ])
    |> as_single_child_of(:stmt)
    |> P.also(P.Delimiter.whitespace())
  end

  @spec decl_parser :: P.parser(Node.t())
  def decl_parser() do
    expect_key_token(:let)
    |> P.also(P.Delimiter.whitespace1())
    |> P.paired_with(identifier_parser())
    |> P.also(P.Delimiter.whitespace())
    |> P.paired_with(expect_key_token(:equals))
    |> P.also(P.Delimiter.whitespace())
    |> P.paired_with(expr_parser())
    |> P.map(fn {{{let, identifier}, equals}, definition} ->
      %PTree.Node{
        type: :decl,
        markers: [let, equals],
        children: [identifier, definition]
      }
    end)
    |> spanned_node()
  end

  @spec expr_parser :: P.parser(Node.t())
  def expr_parser do
    &expr_parser/1
  end

  def expr_parser(state) do
    P.Delimiter.whitespace()
    |> P.then(
      P.alternatives([
        lambda_parser(),
        application_parser()
      ])
    )
    |> as_single_child_of(:expr)
    |> then(& &1.(state))
  end

  @spec lambda_parser :: P.parser(Node.t())
  def lambda_parser do
    expect_key_token(:backslash)
    |> P.also(P.Delimiter.whitespace())
    |> P.paired_with(identifier_parser())
    |> P.also(P.Delimiter.whitespace())
    |> P.paired_with(expect_key_token(:arrow))
    |> P.paired_with(expr_parser())
    |> P.map(fn {{{backslash, param_id}, arrow}, body_expr} ->
      %PTree.Node{
        type: :lambda,
        markers: [backslash, arrow],
        children: [param_id, body_expr]
      }
    end)
    |> spanned_node()
  end

  @spec application_parser :: P.parser(Node.t())
  def application_parser do
    P.at_least_one(application_sequence_item())
    |> P.paired_with(
      P.optional(
        P.Delimiter.whitespace()
        |> P.then(lambda_parser())
        |> P.backtracking()
      )
    )
    |> P.map(fn {[app_head | app_args], trailing_lambda} ->
      app_args =
        if trailing_lambda do
          app_args ++ [trailing_lambda]
        else
          app_args
        end

      span =
        Enum.reduce(
          app_args,
          app_head.span,
          fn
            arg, nil ->
              arg.span

            %{span: nil}, span ->
              span

            %{span: arg_span}, span ->
              P.Position.Span.extend(span, arg_span)
          end
        )

      %PTree.Node{
        type: :application,
        markers: [],
        children: [app_head, app_args],
        span: span
      }
    end)
  end

  def application_sequence_item do
    P.Delimiter.whitespace()
    |> P.then(
      P.alternatives([
        parens(expr_parser()),
        identifier_parser(),
        literal_integer_parser()
      ])
    )
  end

  def parens(parser) do
    expect_key_token(:open_paren)
    |> P.also(P.Delimiter.whitespace())
    |> P.paired_with(parser)
    |> P.also(P.Delimiter.whitespace())
    |> P.paired_with(expect_key_token(:close_paren))
    |> P.map(fn {{open_paren, item}, close_paren} ->
      %PTree.Node{
        type: :parens,
        markers: [open_paren, close_paren],
        children: [item]
      }
    end)
    |> spanned_node()
  end

  def identifier_parser do
    P.String.at_least_one_grapheme_matching(
      fn g ->
        Regex.match?(~r/[a-z]/, g)
      end,
      "lowercase letter"
    )
    |> as_atom_node(:identifier)
  end

  def literal_integer_parser do
    Parsers.Numbers.integer()
    |> as_single_child_of(:literal_integer)
  end

  defp expect_key_token(type) do
    key_token(type) |> as_atom_node(type)
  end

  defp key_token(:open_paren) do
    P.String.expect("(")
  end

  defp key_token(:close_paren) do
    P.String.expect(")")
  end

  defp key_token(:let) do
    P.String.expect("let")
  end

  defp key_token(:equals) do
    P.String.expect("=")
  end

  defp key_token(:backslash) do
    P.String.expect("\\")
  end

  defp key_token(:arrow) do
    P.String.expect("->")
  end

  # Generic helpers

  defp as_atom_node(string_parser, type) do
    string_parser
    |> P.map(fn
      name when is_atom(name) ->
        %PTree.Node{
          type: type,
          markers: [name],
          children: []
        }

      name when is_binary(name) ->
        %PTree.Node{
          type: type,
          markers: [String.to_atom(name)],
          children: []
        }
    end)
    |> spanned_node()
  end

  defp as_single_child_of(child_parser, parent_type) do
    child_parser
    |> P.map(fn child ->
      %PTree.Node{
        type: parent_type,
        children: [child],
        markers: []
      }
    end)
    |> spanned_node()
  end

  def spanned_node(node_parser) do
    node_parser
    |> P.with_span()
    |> P.map(fn {node, span} ->
      %PTree.Node{
        node
        | span: span
      }
    end)
  end
end
