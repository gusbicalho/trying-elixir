defmodule LambdaCalculus do
  @moduledoc """

  """

  use Boundary,
    deps: [Parsers],
    exports: []

  alias LambdaCalculus.Pipeline.AST

  def test_parse_stmt(s, source_name \\ nil) do
    with {parse_result, leftovers} <-
           LambdaCalculus.Pipeline.TextToParseTree.parse_stmt(s, source_name: source_name),
         nil <-
           (if leftovers !== "" do
              {:error, ["unexpected ", leftovers]}
            end),
         {:ok, stmt} <- parse_result,
         {:ok, stmt} <- LambdaCalculus.Pipeline.ParseTreeToAST.Statement.parse(stmt),
         stmt = LambdaCalculus.Pipeline.ASTAnalysis.Scope.analyze(stmt) do
      stmt
    end
  end

  def test_parse do
    %AST.Statement{
      statement: %AST.Expression{
        expression: %AST.Lambda{
          parameter: %AST.Identifier{name: :q},
          body: %AST.Expression{
            expression: %AST.Application{
              function: %AST.Expression{
                expression: %AST.Application{
                  function: %AST.Expression{
                    expression: %AST.Lookup{
                      lookup: %AST.Identifier{name: :plus},
                      meta: [{:scope, :global} | _]
                    }
                  },
                  argument: %AST.Expression{
                    expression: %AST.Lookup{
                      lookup: %AST.Identifier{name: :q},
                      meta: [{:scope, {:local, 0}} | _]
                    }
                  }
                }
              },
              argument: %AST.Expression{
                expression: %AST.Literal{
                  literal: 1
                }
              }
            }
          }
        }
      }
    } = test_parse_stmt("\\ q -> plus q 1      ")

    %AST.Statement{
      statement: %AST.Declaration{
        name: %AST.Identifier{name: :id},
        definition: %AST.Expression{
          expression: %AST.Lambda{
            parameter: %AST.Identifier{name: :a},
            body: %AST.Expression{
              expression: %AST.Lookup{
                lookup: %AST.Identifier{name: :a},
                meta: [{:scope, {:local, 0}} | _]
              }
            }
          }
        }
      }
    } = test_parse_stmt("let id = \\a -> a              ", "second.lam")

    nil
  end

  def test_eval_server() do
    alias LambdaCalculus.EvalServer
    {:ok, pid} = EvalServer.start_link([])
    eval = fn s -> EvalServer.eval(pid, s) end

    {:ok, 5} = eval.("plus 2 3")
    {:ok, 5} = eval.("let five = plus 2 3")
    {:ok, _} = eval.("let p = plus")
    {:ok, 5} = eval.("p 2 3")
    {:ok, _} = eval.("let id = \\a -> a")
    {:ok, 5} = eval.("id p 2 3")

    {:ok, _} = eval.("let times = \\m -> \\n -> repeatedly m (plus n) 0")
    {:ok, 42} = eval.("times 6 7")

    {:ok, _} = eval.("let nil = \\cons -> \\nil -> nil")
    {:ok, _} = eval.("let cons = \\head -> \\tail -> \\cons -> \\nil -> cons head (tail cons nil)")
    {:ok, _} = eval.("let sum = \\list -> list plus 0")
    {:ok, _} = eval.("let product = \\list -> list times 1")
    {:ok, _} = eval.("let somelist = cons 2 (cons 4 (cons 6 nil))")
    {:ok, 12} = eval.("sum somelist")
    {:ok, 48} = eval.("product somelist")

    # the global scope is dynamic!
    {:ok, _} = eval.("let times = plus")
    {:ok, 13} = eval.("product somelist")

    :ok
  end
end
