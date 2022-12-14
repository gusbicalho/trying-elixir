defmodule LambdaCalculus.BuiltIns do
  use Boundary

  def built_ins() do
    %{
      plus: &plus/2,
      repeatedly: &repeatedly/2,
    }
  end

  # Native functions
  def plus(_global_env, v1) do
    fn _, v2 -> v1 + v2 end
  end

  def repeatedly(_global_env, num_times) do
    fn _, f ->
      fn global_env, arg ->
        go_repeatedly(num_times, f, global_env, arg)
      end
    end
  end

  def go_repeatedly(times_left, f, global_env, arg) when is_integer(times_left) and times_left > 0 do
    go_repeatedly(times_left - 1, f, global_env, f.(global_env, arg))
  end

  def go_repeatedly(_, _, _, arg) do
    arg
  end
end
