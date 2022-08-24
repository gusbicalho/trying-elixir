defmodule TodoList do
  defstruct auto_id: 1, entries: %{}

  def new(entries \\ []) do
    Enum.reduce(
      entries,
      %TodoList{},
      &add_entry(&2, &1).todo_list
    )
  end

  def add_entry(%TodoList{} = todo_list, %{date: _} = entry) do
    entry = Map.put(entry, :id, todo_list.auto_id)

    %{
      entry: entry,
      todo_list: %TodoList{
        todo_list
        | auto_id: todo_list.auto_id + 1,
          entries: Map.put_new(todo_list.entries, entry.id, entry)
      }
    }
  end

  def entries(%TodoList{} = todo_list, date) do
    todo_list.entries
    |> Stream.filter(fn {_, entry} ->
      entry.date === date
    end)
    |> Enum.map(fn {_, entry} -> entry end)
  end

  def update_entry(%TodoList{} = todo_list, entry_id, %{} = new_entry) do
    update_entry(todo_list, entry_id, fn _ -> new_entry end)
  end

  def update_entry(%TodoList{} = todo_list, entry_id, updater_fun) do
    update_in(todo_list.entries[entry_id], fn old_entry ->
      %{id: ^entry_id, date: _} = updater_fun.(old_entry)
    end)
  end

  def delete_entry(%TodoList{} = todo_list, entry_id) do
    update_in(todo_list.entries, fn entries -> Map.delete(entries, entry_id) end)
  end
end

defmodule SimpleTodo do
  def run do
    todos =
      TodoList.new([
        %{date: ~D[2018-12-19], title: "Dentist"},
        %{date: ~D[2018-12-20], title: "Shopping"},
        %{date: ~D[2018-12-19], title: "Movies"}
      ])
      |> IO.inspect()

    TodoList.entries(todos, ~D[2018-12-19])
    |> IO.inspect()

    todos
    |> TodoList.update_entry(2, fn entry ->
      %{entry | date: ~D[2018-12-19]}
    end)
    |> TodoList.delete_entry(1)
    |> IO.inspect()
    |> TodoList.entries(~D[2018-12-19])
    |> IO.inspect()
  end
end
