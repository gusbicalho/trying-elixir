defmodule LambdaCalculus.Cli do
  use Boundary,
    deps: [
      LambdaCalculus.BuiltIns,
      LambdaCalculus.ProcessRegistry,
      LambdaCalculus.Repl,
    ]

  use Application

  alias LambdaCalculus.Cli.System

  def start(_type, _args) do
    System.start_link()
  end

  defdelegate create_session(session_name \\ :default), to: System
  defdelegate interact(session_name \\ :default), to: System
  defdelegate interact_directly(session_name \\ :default), to: System
end
