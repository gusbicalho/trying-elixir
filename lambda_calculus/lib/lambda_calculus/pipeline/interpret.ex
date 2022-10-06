defmodule LambdaCalculus.Pipeline.Interpret do
  alias LambdaCalculus.Pipeline.ParseTree.Node
  alias LambdaCalculus.Pipeline.AST
  alias LambdaCalculus.Pipeline.ASTAnalysis.Scope
  alias LambdaCalculus.Pipeline.Runtime

  @type meta() :: [scope: Scope.scope(), parse_node: Node.t()]

  @spec interpret_statement(Runtime.global_env(), AST.Statement.t(meta())) ::
          {:ok, {Runtime.global_env(), Runtime.value()}} | {:error, any()}
  def interpret_statement(%{} = global_env, %AST.Statement{} = stmt) do
    case stmt.statement do
      %AST.Declaration{name: name, definition: expr} ->
        with {:ok, term} <- interpret_expression(global_env, expr) do
          {:ok, {Map.merge(global_env, %{name.name => term}), term}}
        end

      %AST.Expression{} = expr ->
        with {:ok, term} <- interpret_expression(global_env, expr) do
          {:ok, {global_env, term}}
        end
    end
  end

  defmodule LambdaError do
    defexception message: "Runtime error"
  end

  @spec interpret_expression(
          Runtime.global_env(),
          AST.Expression.t(scope: :global | {:local, non_neg_integer()})
        ) ::
          {:ok, Runtime.value()} | {:error, any()}
  def interpret_expression(%{} = global_env, %AST.Expression{} = expr) do
    with {:ok, compiled_expr} <- compile(expr) do
      try do
        {:ok, compiled_expr.(global_env, [])}
      rescue
        e in LambdaError -> {:error, e.message}
      end
    end
  end

  @spec compile(any()) ::
          {:ok, (Runtime.global_env(), Runtime.local_env() -> Runtime.value())}
          | {:error, any()}
  defp compile(%AST.Expression{expression: child}) do
    compile(child)
  end

  defp compile(%AST.Lambda{parameter: parameter, body: body}) do
    with {:ok, compiled_body} <- compile(body) do
      lambda = fn _, locals ->
        fn global_env, argument ->
          compiled_body.(global_env, [{parameter.name, argument} | locals])
        end
      end

      {:ok, lambda}
    end
  end

  defp compile(%AST.Application{function: function, argument: argument}) do
    with {:ok, compiled_function} <- compile(function),
         {:ok, compiled_argument} <- compile(argument) do
      apply = fn global_env, locals ->
        runtime_function = compiled_function.(global_env, locals)
        runtime_argument = compiled_argument.(global_env, locals)
        runtime_function.(global_env, runtime_argument)
      end

      {:ok, apply}
    end
  end

  defp compile(%AST.Lookup{lookup: %AST.Identifier{name: name}, meta: meta}) do
    lookup =
      case Keyword.fetch(meta, :scope) do
        :error ->
          raise LambdaError, message: "Bad local lookup for #{name}: no scope annotation"

        {:ok, :global} ->
          fn global_env, _ ->
            Map.get_lazy(global_env, name, fn ->
              raise LambdaError, message: "Undefined global #{name}"
            end)
          end

        {:ok, {:local, de_brujn_index}} ->
          fn _, locals ->
            case Enum.at(locals, de_brujn_index) do
              {^name, value} ->
                value

              {other_name, _} ->
                raise LambdaError,
                  message: "Bad local lookup for #{name}: index #{de_brujn_index} finds named #{other_name}"

              nil ->
                raise LambdaError,
                  message: "Bad local lookup for #{name}: out-of-bounds index #{de_brujn_index}"
            end
          end
      end

    {:ok, lookup}
  end

  defp compile(%AST.Literal{literal: value}) do
    {:ok, fn _, _ -> value end}
  end
end
