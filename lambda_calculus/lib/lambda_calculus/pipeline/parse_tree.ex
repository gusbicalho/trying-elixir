defmodule LambdaCalculus.Pipeline.ParseTree do
  defmodule Expression do
    defstruct [:expression]
  end

  defmodule Lambda do
    defstruct [:parameter, :body]

    def new_expr(parameter, body) do
      as_expr(new(parameter, body))
    end

    def new(parameter, %Expression{} = body) when is_binary(parameter) do
      %__MODULE__{parameter: parameter, body: body}
    end

    def as_expr(%__MODULE__{} = lambda) do
      %Expression{expression: lambda}
    end
  end

  defmodule Application do
    defstruct [:function, :argument]

    def new_expr(function, argument) do
      as_expr(new(function, argument))
    end

    def new(%Expression{} = function, %Expression{} = argument) do
      %__MODULE__{function: function, argument: argument}
    end

    def as_expr(%__MODULE__{} = application) do
      %Expression{expression: application}
    end
  end

  defmodule Lookup do
    defstruct [:lookup]

    def new_expr(identifier) do
      as_expr(new(identifier))
    end

    def new(identifier) when is_binary(identifier) do
      %__MODULE__{lookup: identifier}
    end

    def as_expr(%__MODULE__{} = lookup) do
      %Expression{expression: lookup}
    end
  end

  defmodule Literal do
    defstruct [:literal]

    def new_expr(identifier) do
      as_expr(new(identifier))
    end

    def new(literal) do
      %__MODULE__{literal: literal}
    end

    def as_expr(%__MODULE__{} = literal) do
      %Expression{expression: literal}
    end
  end

  defmodule Declaration do
    defstruct [:name, :definition]

    def new(name, %Expression{} = definition) when is_binary(name) do
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
