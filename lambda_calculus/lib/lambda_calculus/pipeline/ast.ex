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

    @type child(meta) ::
            Lambda.t(meta) | Application.t(meta) | Lookup.t(meta) | Literal.t(meta)

    typedstruct do
      parameter :meta

      field :expression, child(meta), enforce: true
      field :meta, meta, default: %{}
    end

    @spec new(value, meta) :: __MODULE__.t(meta) when meta: any(), value: child(meta)
    def new(value, meta) do
      %__MODULE__{expression: value, meta: meta}
    end
  end

  defmodule Identifier do
    use TypedStruct

    typedstruct do
      parameter :meta

      field :name, atom, enforce: true
      field :meta, meta, default: %{}
    end

    @spec new(atom, meta) :: __MODULE__.t(meta) when meta: any()
    def new(name, meta) when is_atom(name) do
      %__MODULE__{name: name, meta: meta}
    end
  end

  defmodule Lambda do
    use TypedStruct

    typedstruct do
      parameter :meta

      field :parameter, Identifier.t(meta), enforce: true
      field :body, Expression.t(meta), enforce: true
      field :meta, meta, default: %{}
    end

    @spec new(Identifier.t(meta), Expression.t(meta), meta) :: __MODULE__.t(meta) when meta: any()
    def new(%Identifier{} = parameter, %Expression{} = body, meta) do
      %__MODULE__{parameter: parameter, body: body, meta: meta}
    end
  end

  defmodule Application do
    use TypedStruct

    typedstruct do
      parameter :meta

      field :function, Expression.t(meta), enforce: true
      field :argument, Expression.t(meta), enforce: true
      field :meta, meta, default: %{}
    end

    @spec new(Expression.t(meta), Expression.t(meta), meta) :: __MODULE__.t(meta) when meta: any()
    def new(%Expression{} = function, %Expression{} = argument, meta) do
      %__MODULE__{function: function, argument: argument, meta: meta}
    end
  end

  defmodule Lookup do
    use TypedStruct

    typedstruct do
      parameter :meta
      field :lookup, Identifier.t(meta), enforce: true
      field :meta, meta, default: %{}
    end

    @spec new(Identifier.t(meta), meta) :: __MODULE__.t(meta) when meta: any()
    def new(%Identifier{} = identifier, meta) do
      %__MODULE__{lookup: identifier, meta: meta}
    end
  end

  defmodule Literal do
    use TypedStruct

    typedstruct do
      parameter :meta
      field :literal, any, enforce: true
      field :meta, meta, default: %{}
    end

    @spec new(any, meta) :: __MODULE__.t(meta) when meta: any()
    def new(literal, meta) do
      %__MODULE__{literal: literal, meta: meta}
    end
  end

  defmodule Declaration do
    use TypedStruct

    typedstruct do
      parameter :meta
      field :name, Identifier.t(meta), enforce: true
      field :definition, Expression.t(meta), enforce: true
      field :meta, meta, default: %{}
    end

    @spec new(Identifier.t(meta), Expression.t(meta), meta) :: __MODULE__.t(meta) when meta: any()
    def new(%Identifier{} = name, %Expression{} = definition, meta) do
      %__MODULE__{name: name, definition: definition, meta: meta}
    end
  end

  defmodule Statement do
    use TypedStruct

    @type child(meta) ::
            Declaration.t(meta) | Expression.t(meta)

    typedstruct do
      parameter :meta
      field :statement, child(meta), enforce: true
      field :meta, meta, default: %{}
    end

    @spec new(child(meta), meta) :: __MODULE__.t(meta) when meta: any()
    def new(value, meta \\ %{})

    def new(%Expression{} = expr, meta) do
      %__MODULE__{statement: expr, meta: meta}
    end

    def new(%Declaration{} = decl, meta) do
      %__MODULE__{statement: decl, meta: meta}
    end
  end
end
