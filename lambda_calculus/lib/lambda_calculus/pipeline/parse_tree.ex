defmodule LambdaCalculus.Pipeline.ParseTree do
  defmodule Node do
    defstruct [:type, :markers, :span, :children]
  end
end
