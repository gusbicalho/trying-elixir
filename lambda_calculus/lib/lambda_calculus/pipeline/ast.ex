defmodule LambdaCalculus.Pipeline.AST do
  alias LambdaCalculus.Pipeline.AST.Expression
  alias LambdaCalculus.Pipeline.AST.Identifier
  alias LambdaCalculus.Pipeline.AST.Lambda
  alias LambdaCalculus.Pipeline.AST.Application
  alias LambdaCalculus.Pipeline.AST.Lookup
  alias LambdaCalculus.Pipeline.AST.Literal
  alias LambdaCalculus.Pipeline.AST.Declaration
  alias LambdaCalculus.Pipeline.AST.Statement

  defmodule Expression do
    use TypedStruct

    @type child() ::
            Lambda.t() | Application.t() | Lookup.t() | Literal.t()

    typedstruct do
      field :expression, child(), enforce: true
      field :meta, map, default: %{}
    end

    @spec new(child(), map) :: __MODULE__.t()
    def new(value, %{} = meta) do
      %__MODULE__{expression: value, meta: meta}
    end
  end

  defmodule Identifier do
    use TypedStruct

    typedstruct do
      field :name, atom, enforce: true
      field :meta, map, default: %{}
    end

    @spec new(atom, map) :: __MODULE__.t()
    def new(name, %{} = meta \\ %{}) when is_atom(name) do
      %__MODULE__{name: name, meta: meta}
    end
  end

  defmodule Lambda do
    use TypedStruct

    typedstruct do
      field :parameter, Identifier.t(), enforce: true
      field :body, Expression.t(), enforce: true
      field :meta, map, default: %{}
    end

    @spec new(Identifier.t(), Expression.t(), map) :: __MODULE__.t()
    def new(%Identifier{} = parameter, %Expression{} = body, %{} = meta \\ %{}) do
      %__MODULE__{parameter: parameter, body: body, meta: meta}
    end
  end

  defmodule Application do
    use TypedStruct

    typedstruct do
      field :function, Expression.t(), enforce: true
      field :argument, Expression.t(), enforce: true
      field :meta, map, default: %{}
    end

    @spec new(Expression.t(), Expression.t(), map) :: __MODULE__.t()
    def new(%Expression{} = function, %Expression{} = argument, %{} = meta \\ %{}) do
      %__MODULE__{function: function, argument: argument, meta: meta}
    end
  end

  defmodule Lookup do
    use TypedStruct

    typedstruct do
      field :lookup, Identifier.t(), enforce: true
      field :meta, map, default: %{}
    end

    @spec new(Identifier.t(), map) :: __MODULE__.t()
    def new(%Identifier{} = identifier, %{} = meta \\ %{}) do
      %__MODULE__{lookup: identifier, meta: meta}
    end
  end

  defmodule Literal do
    use TypedStruct

    typedstruct do
      field :literal, any, enforce: true
      field :meta, map, default: %{}
    end

    @spec new(any, map) :: __MODULE__.t()
    def new(literal, %{} = meta \\ %{}) do
      %__MODULE__{literal: literal, meta: meta}
    end
  end

  defmodule Declaration do
    use TypedStruct

    typedstruct do
      field :name, Identifier.t(), enforce: true
      field :definition, Expression.t(), enforce: true
      field :meta, map, default: %{}
    end

    @spec new(Identifier.t(), Expression.t(), map) :: __MODULE__.t()
    def new(%Identifier{} = name, %Expression{} = definition, %{} = meta \\ %{}) do
      %__MODULE__{name: name, definition: definition, meta: meta}
    end
  end

  defmodule Statement do
    use TypedStruct

    @type child() ::
            Declaration.t() | Expression.t()

    typedstruct do
      field :statement, child(), enforce: true
      field :meta, map, default: %{}
    end

    @spec new(child(), map) :: __MODULE__.t()
    def new(value, meta \\ %{})

    def new(%Expression{} = expr, %{} = meta) do
      %__MODULE__{statement: expr, meta: meta}
    end

    def new(%Declaration{} = decl, %{} = meta) do
      %__MODULE__{statement: decl, meta: meta}
    end
  end
end
