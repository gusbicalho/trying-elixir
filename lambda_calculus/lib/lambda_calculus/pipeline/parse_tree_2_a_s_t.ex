defmodule LambdaCalculus.Pipeline.ParseTreeAST do
  alias LambdaCalculus.Pipeline.ParseTree.Node
  alias LambdaCalculus.Pipeline.AST

  defp meta_from(%Node{} = parse_node) do
    %{parse_node: parse_node}
    %{position_span: parse_node.span}
  end

  def parse_node_to_stmt(%Node{type: :stmt} = parse_node) do
    case parse_node do
      %Node{children: [child]} ->
        with {:ok, child} <- stmt_child(child) do
          {:ok, AST.Statement.new(child, meta_from(parse_node))}
        end

      other_node ->
        {:error, [:malformed_stmt_node, other_node]}
    end
  end

  def parse_node_to_stmt(other_node) do
    {:error, [:expected_stmt_node, other_node]}
  end

  defp stmt_child(%Node{type: :decl} = node) do
    parse_node_to_declaration(node)
  end

  defp stmt_child(%Node{type: :expr} = node) do
    parse_node_to_expression(node)
  end

  defp stmt_child(other_node) do
    {:error, [:expected_declaration_or_expression, other_node]}
  end

  def parse_node_to_declaration(%Node{type: :decl} = parse_node) do
    case parse_node do
      %Node{children: [identifier_node, definition_node]} ->
        with {:ok, identifier} <- parse_node_to_identifier(identifier_node),
             {:ok, definition} <- parse_node_to_expression(definition_node) do
          {:ok, AST.Declaration.new(identifier, definition, meta_from(parse_node))}
        end

      other_node ->
        {:error, [:malformed_decl_node, other_node]}
    end
  end

  def parse_node_to_declaration(other_node) do
    {:error, [:expected_decl_node, other_node]}
  end

  def parse_node_to_expression(%Node{type: :expr} = parse_node) do
    case parse_node do
      %Node{children: [child]} ->
        expr_child(child, parse_node)

      other_node ->
        {:error, [:malformed_expr_node, other_node]}
    end
  end

  def parse_node_to_expression(other_node) do
    {:error, [:expected_expr_node, other_node]}
  end

  defp expr_child(%Node{type: :lambda} = child_node, expr_node) do
    with {:ok, lambda} <- parse_node_to_lambda(child_node) do
      {:ok, AST.Expression.new(lambda, meta_from(expr_node))}
    end
  end

  defp expr_child(%Node{type: :application} = child_node, expr_node) do
    with {:ok, application_expr} <- parse_node_to_application(child_node) do
      {:ok,
       %AST.Expression{
         application_expr
         | meta: meta_from(expr_node)
       }}
    end
  end

  defp expr_child(other_node, _expr_node) do
    {:error, [:expected_lambda_or_application, other_node]}
  end

  def parse_node_to_identifier(%Node{type: :identifier} = parse_node) do
    case parse_node do
      %Node{markers: [name]} when is_atom(name) ->
        {:ok, AST.Identifier.new(name, meta_from(parse_node))}

      other_node ->
        {:error, [:malformed_identifier_node, other_node]}
    end
  end

  def parse_node_to_identifier(other_node) do
    {:error, [:expected_identifier_node, other_node]}
  end

  def parse_node_to_lambda(%Node{type: :lambda} = parse_node) do
    case parse_node do
      %Node{children: [param_node, body_node]} ->
        with {:ok, param} <- parse_node_to_identifier(param_node),
             {:ok, body} <- parse_node_to_expression(body_node) do
          {:ok, AST.Lambda.new(param, body, meta_from(parse_node))}
        end

      other_node ->
        {:error, [:malformed_lambda_node, other_node]}
    end
  end

  def parse_node_to_lambda(other_node) do
    {:error, [:expected_lambda_node, other_node]}
  end

  def parse_node_to_application(%Node{type: :application} = parse_node) do
    case parse_node do
      %Node{children: [app_head_node, app_args_nodes]} ->
        with {:ok, app_head} <- parse_application_item_to_expression(app_head_node),
             {:ok, app_args} <- parse_argument_nodes_to_arguments(app_args_nodes) do
          {:ok,
           Enum.reduce(
             app_args,
             app_head,
             fn arg, head ->
               AST.Expression.new(
                 AST.Application.new(
                   head,
                   arg,
                   meta_from(parse_node)
                 ),
                 meta_from(parse_node)
               )
             end
           )}
        end

      other_node ->
        {:error, [:malformed_application_node, other_node]}
    end
  end

  def parse_node_to_application(other_node) do
    {:error, [:expected_application_node, other_node]}
  end

  def parse_application_item_to_expression(%Node{type: :parens} = parse_node) do
    case parse_node do
      %Node{children: [child]} ->
        parse_node_to_expression(child)

      other_node ->
        {:error, [:malformed_parens_node, other_node]}
    end
  end

  def parse_application_item_to_expression(%Node{type: :identifier} = parse_node) do
    with {:ok, identifier} <- parse_node_to_identifier(parse_node) do
      {:ok,
       AST.Expression.new(
         AST.Lookup.new(identifier, meta_from(parse_node)),
         meta_from(parse_node)
       )}
    end
  end

  def parse_application_item_to_expression(%Node{type: :literal_integer} = parse_node) do
    case parse_node do
      %Node{children: [integer]} when is_integer(integer) ->
        {:ok,
         AST.Expression.new(
           AST.Literal.new(integer, meta_from(parse_node)),
           meta_from(parse_node)
         )}

      other_node ->
        {:error, [:malformed_literal_integer_node, other_node]}
    end
  end

  def parse_application_item_to_expression(other_node) do
    {:error, [:unexpected_application_item, other_node]}
  end

  def parse_argument_nodes_to_arguments([]), do: {:ok, []}

  def parse_argument_nodes_to_arguments([arg_node | more_arg_nodes]) do
    with {:ok, arg} <- parse_application_item_to_expression(arg_node),
         {:ok, more_args} <- parse_argument_nodes_to_arguments(more_arg_nodes) do
      {:ok, [arg | more_args]}
    end
  end

  # def parse_node_to_identifier(%Node{type: :identifier} = parse_node) do
  #   case parse_node do
  #     :TODO -> nil
  #     other_node ->
  #       {:error, [:malformed_identifier_node, other_node]}
  #   end
  # end

  # def parse_node_to_identifier(other_node) do
  #   {:error, [:expected_identifier_node, other_node]}
  # end
end
