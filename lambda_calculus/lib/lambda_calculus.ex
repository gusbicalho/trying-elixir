defmodule LambdaCalculus do
  @moduledoc """

  """

  alias LambdaCalculus.Pipeline.AST

  def test_stmt(s, source_name \\ nil) do
    {parsed_stmt, ""} =
      Parsers.run!(
        LambdaCalculus.Pipeline.Parser.stmt_parser(),
        s,
        source_name: source_name
      )

    {:ok, stmt} = LambdaCalculus.Pipeline.ParseTreeAST.parse_node_to_stmt(parsed_stmt)

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
    } =
      "\\ q -> plus q 1      "
      |> IO.inspect()
      |> test_stmt()
      |> IO.inspect()

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
    } =
      "let id = \\a -> a              "
      |> IO.inspect()
      |> test_stmt("second.lam")
      |> IO.inspect()

    nil
  end
end
