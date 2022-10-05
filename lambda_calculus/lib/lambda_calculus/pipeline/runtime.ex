defmodule LambdaCalculus.Pipeline.Runtime do
  @type value() :: integer() | (global_env(), value() -> value())
  @type global_env() :: %{atom() => value()}
  @type local_env() :: [{atom(), value()}]
end
