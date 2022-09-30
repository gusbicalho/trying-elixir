defmodule LambdaCalculus do
  @moduledoc """

  """

  alias LambdaCalculus.Pipeline.AST

  def test_stmt(s, source_name \\ nil) do
    {parsed_stmt, ""} =
      Parsers.run!(
        LambdaCalculus.Pipeline.TextToParseTree.stmt_parser(),
        s,
        source_name: source_name
      )

    {:ok, stmt} = LambdaCalculus.Pipeline.ParseTreeToAST.Statement.parse(parsed_stmt)

    stmt
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
                    expression: %AST.Lookup{lookup: %AST.Identifier{name: :plus}}
                  },
                  argument: %AST.Expression{
                    expression: %AST.Lookup{lookup: %AST.Identifier{name: :q}}
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
                lookup: %AST.Identifier{name: :a}
              }
            }
          }
        }
      }
    } = test_stmt("let id = \\a -> a              ", "second.lam")

    nil
  end
end
