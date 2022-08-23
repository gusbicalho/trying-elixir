defmodule Reducer do
  def start_link(f, zero) do
    Task.start_link(fn -> loop(f, zero) end)
  end

  defp loop(f, state) do
    receive do
      msg -> loop(f, f.(state, msg))
    end
  end
end

defmodule KV do
  def start_link do
    Reducer.start_link(&handle/2, %{})
  end

  defp handle(map, {:get, key, caller}) do
    send(caller, Map.get(map, key))
    map
  end
  defp handle(map, {:put, key, value}) do
    Map.put(map, key, value)
  end
end
