defmodule LambdaCalculus do
  @moduledoc """

  """

  use Boundary,
    deps: [Parsers],
    exports: []

  alias LambdaCalculus.Pipeline.AST

  def test_stmt(s, source_name \\ nil) do
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

  def test do
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
    } = test_stmt("\\ q -> plus q 1      ")

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
    } = test_stmt("let id = \\a -> a              ", "second.lam")

    nil
  end
end
