defmodule LambdaCalculus.Pipeline.ASTAnalysis.Scope do
  alias LambdaCalculus.Pipeline.AST

  @type scope :: :global | {:local, non_neg_integer()}
  @type with_scope(meta) :: [scope: scope | meta] | meta

  @spec analyze(AST.Statement.t(meta)) :: AST.Statement.t(with_scope(meta)) when meta: Keyword.t()
  def analyze(%AST.Statement{} = stmt) do
    analyze_stmt(stmt, [])
  end

  defp analyze_stmt(%AST.Statement{} = stmt, locals) do
    update_in(stmt.statement, fn
      %AST.Declaration{} = decl -> analyze_decl(decl, locals)
      %AST.Expression{} = expr -> analyze_expr(expr, locals)
    end)
  end

  defp analyze_decl(%AST.Declaration{} = decl, locals) do
    update_in(decl.definition, &analyze_expr(&1, locals))
  end

  defp analyze_expr(%AST.Expression{} = expr, locals) do
    update_in(expr.expression, fn
      %AST.Lambda{} = lambda -> analyze_lambda(lambda, locals)
      %AST.Application{} = application -> analyze_application(application, locals)
      %AST.Lookup{} = lookup -> analyze_lookup(lookup, locals)
      %AST.Literal{} = literal -> literal
    end)
  end

  defp analyze_lambda(%AST.Lambda{} = lambda, locals) do
    %AST.Identifier{name: param_name} = lambda.parameter
    locals = [param_name | locals]
    update_in(lambda.body, &analyze_expr(&1, locals))
  end

  defp analyze_application(%AST.Application{} = application, locals) do
    application
    |> update_in([Access.key!(:function)], &analyze_expr(&1, locals))
    |> update_in([Access.key!(:argument)], &analyze_expr(&1, locals))
  end

  defp analyze_lookup(%AST.Lookup{} = lookup, locals) do
    %AST.Lookup{lookup: %AST.Identifier{name: lookup_name}} = lookup

    update_in(
      lookup.meta,
      fn meta ->
        Keyword.put(
          meta,
          :scope,
          case Enum.find_index(locals, &(&1 === lookup_name)) do
            nil -> :global
            de_brujn_index -> {:local, de_brujn_index}
          end
        )
      end
    )
  end
end
