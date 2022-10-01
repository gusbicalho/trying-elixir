defmodule LambdaCalculus.Pipeline.ParseTree do
  defmodule Node do
    use TypedStruct

    typedstruct do
      field :type, atom(), enforce: true
      field :markers, list(any), default: []
      field :children, list(Node.t()), default: []
      field :span, Parsers.Position.Span.t() | nil
    end
  end
end
