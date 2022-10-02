defmodule LambdaCalculus.Pipeline.ParseTreeToAST do
  alias LambdaCalculus.Pipeline.ParseTree.Node
  alias LambdaCalculus.Pipeline.AST
  alias __MODULE__.Declaration
  alias __MODULE__.Expression
  alias __MODULE__.Application
  alias __MODULE__.Lambda
  alias __MODULE__.Identifier

  defmodule Meta do
    @type t() :: [parse_node: Node.t()]
    def meta_from(%Node{} = parse_node) do
      [parse_node: parse_node]
    end
  end

  defmodule Statement do
    @spec parse(Node.t()) :: {:error, [...]} | {:ok, AST.Statement.t(Meta.t())}
    def parse(%Node{type: :stmt} = parse_node) do
      case parse_node do
        %Node{children: [child]} ->
          with {:ok, child} <- stmt_child(child) do
            {:ok, AST.Statement.new(child, Meta.meta_from(parse_node))}
          end

        other_node ->
          {:error, [:malformed_stmt_node, other_node]}
      end
    end

    def parse(%Node{} = other_node) do
      {:error, [:expected_stmt_node, other_node]}
    end

    defp stmt_child(%Node{type: :decl} = node) do
      Declaration.parse(node)
    end

    defp stmt_child(%Node{type: :expr} = node) do
      Expression.parse(node)
    end

    defp stmt_child(other_node) do
      {:error, [:expected_declaration_or_expression, other_node]}
    end
  end

  defmodule Declaration do
    def parse(%Node{type: :decl} = parse_node) do
      case parse_node do
        %Node{children: [identifier_node, definition_node]} ->
          with {:ok, identifier} <- Identifier.parse(identifier_node),
               {:ok, definition} <- Expression.parse(definition_node) do
            {:ok, AST.Declaration.new(identifier, definition, Meta.meta_from(parse_node))}
          end

        other_node ->
          {:error, [:malformed_decl_node, other_node]}
      end
    end

    def parse(other_node) do
      {:error, [:expected_decl_node, other_node]}
    end
  end

  defmodule Expression do
    def parse(%Node{type: :expr} = parse_node) do
      case parse_node do
        %Node{children: [child]} ->
          expr_child(child, parse_node)

        other_node ->
          {:error, [:malformed_expr_node, other_node]}
      end
    end

    def parse(%Node{} = other_node) do
      {:error, [:expected_expr_node, other_node]}
    end

    defp expr_child(%Node{type: :lambda} = child_node, expr_node) do
      with {:ok, lambda} <- Lambda.parse(child_node) do
        {:ok, AST.Expression.new(lambda, Meta.meta_from(expr_node))}
      end
    end

    defp expr_child(%Node{type: :application} = child_node, expr_node) do
      with {:ok, application_expr} <- Application.parse(child_node) do
        {:ok,
         %AST.Expression{
           application_expr
           | meta: Meta.meta_from(expr_node)
         }}
      end
    end

    defp expr_child(other_node, _expr_node) do
      {:error, [:expected_lambda_or_application, other_node]}
    end
  end

  defmodule Identifier do
    def parse(%Node{type: :identifier} = parse_node) do
      case parse_node do
        %Node{markers: [name]} when is_atom(name) ->
          {:ok, AST.Identifier.new(name, Meta.meta_from(parse_node))}

        other_node ->
          {:error, [:malformed_identifier_node, other_node]}
      end
    end

    def parse(%Node{} = other_node) do
      {:error, [:expected_identifier_node, other_node]}
    end
  end

  defmodule Lambda do
    def parse(%Node{type: :lambda} = parse_node) do
      case parse_node do
        %Node{children: [param_node, body_node]} ->
          with {:ok, param} <- Identifier.parse(param_node),
               {:ok, body} <- Expression.parse(body_node) do
            {:ok, AST.Lambda.new(param, body, Meta.meta_from(parse_node))}
          end

        other_node ->
          {:error, [:malformed_lambda_node, other_node]}
      end
    end

    def parse(%Node{} = other_node) do
      {:error, [:expected_lambda_node, other_node]}
    end
  end

  defmodule Application do
    def parse(%Node{type: :application} = parse_node) do
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
                     Meta.meta_from(parse_node)
                   ),
                   Meta.meta_from(parse_node)
                 )
               end
             )}
          end

        other_node ->
          {:error, [:malformed_application_node, other_node]}
      end
    end

    def parse(%Node{} = other_node) do
      {:error, [:expected_application_node, other_node]}
    end

    defp parse_application_item_to_expression(%Node{type: :parens} = parse_node) do
      case parse_node do
        %Node{children: [child]} ->
          Expression.parse(child)

        other_node ->
          {:error, [:malformed_parens_node, other_node]}
      end
    end

    defp parse_application_item_to_expression(%Node{type: :identifier} = parse_node) do
      with {:ok, identifier} <- Identifier.parse(parse_node) do
        {:ok,
         AST.Expression.new(
           AST.Lookup.new(identifier, Meta.meta_from(parse_node)),
           Meta.meta_from(parse_node)
         )}
      end
    end

    defp parse_application_item_to_expression(%Node{type: :literal_integer} = parse_node) do
      case parse_node do
        %Node{children: [integer]} when is_integer(integer) ->
          {:ok,
           AST.Expression.new(
             AST.Literal.new(integer, Meta.meta_from(parse_node)),
             Meta.meta_from(parse_node)
           )}

        other_node ->
          {:error, [:malformed_literal_integer_node, other_node]}
      end
    end

    defp parse_application_item_to_expression(other_node) do
      {:error, [:unexpected_application_item, other_node]}
    end

    defp parse_argument_nodes_to_arguments([]), do: {:ok, []}

    defp parse_argument_nodes_to_arguments([arg_node | more_arg_nodes]) do
      with {:ok, arg} <- parse_application_item_to_expression(arg_node),
           {:ok, more_args} <- parse_argument_nodes_to_arguments(more_arg_nodes) do
        {:ok, [arg | more_args]}
      end
    end
  end
end
