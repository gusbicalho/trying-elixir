defmodule LambdaCalculus.Pipeline.ParseTree do
  alias Parsers, as: P

  defmodule Expression.Meta do
    defstruct [:position_span]

    def new(meta \\ []) do
      position_span = meta[:position_span]
      if position_span, do: %P.Position.Span{} = position_span
      %__MODULE__{position_span: position_span}
    end
  end

  defmodule Expression do
    defstruct [:expression, meta: Expression.Meta.new()]
  end

  defmodule Identifier.Meta do
    defstruct [:position_span]

    def new(meta \\ []) do
      position_span = meta[:position_span]
      if position_span, do: %P.Position.Span{} = position_span
      %__MODULE__{position_span: position_span}
    end
  end

  defmodule Identifier do
    defstruct [:name, meta: %Identifier.Meta{}]

    def new(name, meta \\ %Identifier.Meta{})

    def new(name, %Identifier.Meta{} = meta) when is_binary(name) do
      %__MODULE__{name: String.to_atom(name), meta: meta}
    end

    def new(name, %Identifier.Meta{} = meta) when is_atom(name) do
      %__MODULE__{name: name, meta: meta}
    end
  end

  defmodule Lambda do
    defstruct [:parameter, :body]

    def new_expr(parameter, body) do
      as_expr(new(parameter, body))
    end

    def new(%Identifier{} = parameter, %Expression{} = body) do
      %__MODULE__{parameter: parameter, body: body}
    end

    def as_expr(%__MODULE__{} = lambda) do
      %Expression{expression: lambda}
    end
  end

  defmodule Application do
    defstruct [:function, :argument]

    def new_expr(function, argument, meta \\ []) do
      as_expr(new(function, argument), meta)
    end

    def new(%Expression{} = function, %Expression{} = argument) do
      %__MODULE__{function: function, argument: argument}
    end

    def as_expr(%__MODULE__{} = application, meta \\ []) do
      %Expression{
        expression: application,
        meta: Expression.Meta.new(meta)
      }
    end
  end

  defmodule Lookup do
    defstruct [:lookup]

    def new_expr(identifier, meta \\ []) do
      as_expr(new(identifier), meta)
    end

    def new(%Identifier{} = identifier) do
      %__MODULE__{lookup: identifier}
    end

    def as_expr(%__MODULE__{} = lookup, meta \\ []) do
      %Expression{
        expression: lookup,
        meta: Expression.Meta.new(meta)
      }
    end
  end

  defmodule Literal do
    defstruct [:literal]

    def new_expr(identifier, meta \\ []) do
      as_expr(new(identifier), meta)
    end

    def new(literal) do
      %__MODULE__{literal: literal}
    end

    def as_expr(%__MODULE__{} = literal, meta \\ []) do
      %Expression{
        expression: literal,
        meta: Expression.Meta.new(meta)
      }
    end
  end

  defmodule Declaration do
    defstruct [:name, :definition]

    def new(%Identifier{} = name, %Expression{} = definition) do
      %__MODULE__{name: name, definition: definition}
    end
  end

  defmodule Statement do
    defstruct [:statement]

    def expression(%Expression{} = expr) do
      %__MODULE__{statement: expr}
    end

    def declaration(%Declaration{} = decl) do
      %__MODULE__{statement: decl}
    end
  end
end
