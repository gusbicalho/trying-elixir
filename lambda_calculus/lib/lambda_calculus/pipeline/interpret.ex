defmodule LambdaCalculus.Pipeline.Interpret do
  alias LambdaCalculus.Pipeline.ParseTree.Node
  alias LambdaCalculus.Pipeline.AST
  alias LambdaCalculus.Pipeline.ASTAnalysis.Scope
  alias LambdaCalculus.Pipeline.Runtime

  @type meta() :: [scope: Scope.scope(), parse_node: Node.t()]

  defmodule CompilationContext do
    use TypedStruct

    typedstruct do
      field :global_env, Runtime.global_env(), default: %{}
      field :defining_global, atom()
    end
  end

  defmodule CompilationWarning do
    use TypedStruct

    typedstruct do
      field :message, iodata()
      field :node, Node.t()
    end

    def new(message, node) do
      %__MODULE__{message: message, node: node}
    end
  end

  @spec interpret_statement(Runtime.global_env(), AST.Statement.t(meta())) ::
          {:ok, {Keyword.t(Runtime.value()), Runtime.value(), [CompilationWarning.t()]}} | {:error, any()}
  def interpret_statement(%{} = global_env, %AST.Statement{} = stmt) do
    case stmt.statement do
      %AST.Declaration{name: %AST.Identifier{name: name}, definition: expr} ->
        context = %CompilationContext{global_env: global_env, defining_global: name}

        with {:ok, term, warnings} <- interpret_expression(context, expr) do
          {:ok, {[{name, term}], term, warnings}}
        end

      %AST.Expression{} = expr ->
        context = %CompilationContext{global_env: global_env}

        with {:ok, term, warnings} <- interpret_expression(context, expr) do
          {:ok, {[], term, warnings}}
        end
    end
  end

  defmodule LambdaError do
    defexception message: "Runtime error"
  end

  @spec interpret_expression(
          CompilationContext.t(),
          AST.Expression.t(scope: :global | {:local, non_neg_integer()})
        ) ::
          {:ok, Runtime.value(), [CompilationWarning.t()]} | {:error, any()}
  def interpret_expression(%CompilationContext{} = context, %AST.Expression{} = expr) do
    with {:ok, compiled_expr, warnings} <- compile(context, expr) do
      try do
        {:ok, compiled_expr.(context.global_env, []), warnings}
      rescue
        e in LambdaError -> {:error, e.message}
      end
    end
  end

  @spec compile(CompilationContext.t(), any()) ::
          {:ok, (Runtime.global_env(), Runtime.local_env() -> Runtime.value()), [CompilationWarning.t()]}
          | {:error, any()}
  defp compile(context, %AST.Expression{expression: child}) do
    compile(context, child)
  end

  defp compile(context, %AST.Lambda{parameter: parameter, body: body}) do
    with {:ok, compiled_body, warnings_body} <- compile(context, body) do
      lambda = fn _, locals ->
        fn global_env, argument ->
          compiled_body.(global_env, [{parameter.name, argument} | locals])
        end
      end

      {:ok, lambda, warnings_body}
    end
  end

  defp compile(context, %AST.Application{function: function, argument: argument}) do
    with {:ok, compiled_function, warnings_function} <- compile(context, function),
         {:ok, compiled_argument, warnings_argument} <- compile(context, argument) do
      apply = fn global_env, locals ->
        runtime_function = compiled_function.(global_env, locals)
        runtime_argument = compiled_argument.(global_env, locals)
        runtime_function.(global_env, runtime_argument)
      end

      {:ok, apply, warnings_function ++ warnings_argument}
    end
  end

  defp compile(context, %AST.Lookup{lookup: %AST.Identifier{name: name}, meta: meta}) do
    case Keyword.fetch(meta, :scope) do
      :error ->
        {:error, "Bad local lookup for #{name}: no scope annotation"}

      {:ok, :global} ->
        lookup_global = fn global_env, _ ->
          Map.get_lazy(global_env, name, fn ->
            raise LambdaError, message: "Undefined global #{name}"
          end)
        end

        warnings =
          [
            check_warning_undefined_global(context, name, Keyword.get(meta, :parse_node))
          ]
          |> Enum.filter(fn v -> v end)

        {:ok, lookup_global, warnings}

      {:ok, {:local, de_brujn_index}} ->
        lookup_local = fn _, locals ->
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

        {:ok, lookup_local, []}
    end
  end

  defp compile(_context, %AST.Literal{literal: value}) do
    {:ok, fn _, _ -> value end, []}
  end

  defp check_warning_undefined_global(%CompilationContext{} = context, name, parse_node) do
    if Map.fetch(context.global_env, name) === :error && context.defining_global !== name do
      CompilationWarning.new("Reference to undefined global #{name}", parse_node)
    end
  end
end
