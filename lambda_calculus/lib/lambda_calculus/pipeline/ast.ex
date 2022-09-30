defmodule LambdaCalculus.Pipeline.AST do
  defmodule Expression do
    defstruct [:expression, meta: %{}]

    def new(value, %{} = meta) do
      %__MODULE__{expression: value, meta: meta}
    end
  end

  defmodule Identifier do
    defstruct [:name, meta: %{}]

    def new(name, %{} = meta \\ %{}) when is_atom(name) do
      %__MODULE__{name: name, meta: meta}
    end
  end

  defmodule Lambda do
    defstruct [:parameter, :body, meta: %{}]

    def new(%Identifier{} = parameter, %Expression{} = body, %{} = meta \\ %{}) do
      %__MODULE__{parameter: parameter, body: body, meta: meta}
    end
  end

  defmodule Application do
    defstruct [:function, :argument, meta: %{}]

    def new(%Expression{} = function, %Expression{} = argument, %{} = meta \\ %{}) do
      %__MODULE__{function: function, argument: argument, meta: meta}
    end
  end

  defmodule Lookup do
    defstruct [:lookup, meta: %{}]

    def new(%Identifier{} = identifier, %{} = meta \\ %{}) do
      %__MODULE__{lookup: identifier, meta: meta}
    end
  end

  defmodule Literal do
    defstruct [:literal, meta: %{}]

    def new(literal, %{} = meta \\ %{}) do
      %__MODULE__{literal: literal, meta: meta}
    end
  end

  defmodule Declaration do
    defstruct [:name, :definition, meta: %{}]

    def new(%Identifier{} = name, %Expression{} = definition, %{} = meta \\ %{}) do
      %__MODULE__{name: name, definition: definition, meta: meta}
    end
  end

  defmodule Statement do
    defstruct [:statement, meta: %{}]

    def new(value, meta \\ %{})

    def new(%Expression{} = expr, %{} = meta) do
      %__MODULE__{statement: expr, meta: meta}
    end

    def new(%Declaration{} = decl, %{} = meta) do
      %__MODULE__{statement: decl, meta: meta}
    end
  end
end
