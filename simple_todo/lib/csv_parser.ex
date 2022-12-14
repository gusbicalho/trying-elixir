defmodule CsvParser do
  def test() do
    CsvParser.parse_line("1,2,3, asd , 4", {
      &CsvParser.Parsers.integer/1,
      &CsvParser.Parsers.integer/1,
      &CsvParser.Parsers.string/1,
      &CsvParser.Parsers.trim/1,
      &CsvParser.Parsers.integer/1
    })
  end

  def parse_lines(lines, columns) do
    Stream.map(lines, &parse_line(&1, columns))
  end

  def parse_text(string, columns) do
    String.splitter(string, "\n")
    |> parse_lines(columns)
  end

  def parse_file!(path, columns) do
    File.stream!(path) |> parse_lines(columns)
  end

  def parse_line(_string, []) do
    {:ok, []}
  end

  def parse_line(string, columns) do
    count_cols = tuple_size(columns)

    with {:ok, list_parsed} <-
           string
           |> String.splitter(",")
           |> Stream.take(count_cols)
           |> Stream.zip_with(
             Tuple.to_list(columns),
             fn text, parse_column ->
               parse_column.(text)
             end
           )
           |> Enum.to_list()
           |> traverse_ok,
         parsed = List.to_tuple(list_parsed),
         :ok <- expect_tuple_size(parsed, count_cols) do
      {:ok, parsed}
    end
  end

  defp traverse_ok(ok_or_errors) do
    go_traverse_ok = fn
      {:ok, value}, acc -> {:cont, [value | acc]}
      {:error, error}, acc -> {:halt, {:error, "Parsing column #{length(acc)}: #{error}"}}
      :error, acc -> {:halt, {:error, "Parsing column #{length(acc)}"}}
    end

    case Enum.reduce_while(ok_or_errors, [], go_traverse_ok) do
      {:error, error} -> {:error, error}
      list -> {:ok, Enum.reverse(list)}
    end
  end

  defp expect_tuple_size(tuple, expected_size) do
    case tuple_size(tuple) do
      ^expected_size -> :ok
      size -> {:error, "Row length mismatch: expected #{expected_size} columns, got #{size}"}
    end
  end
end

defmodule CsvParser.Parsers do
  def string(string) do
    {:ok, string}
  end

  def trim(string) do
    {:ok, String.trim(string)}
  end

  def integer(string, base \\ 10) do
    string = String.trim(string)

    case Integer.parse(string, base) do
      {i, ""} -> {:ok, i}
      {_i, leftovers} -> {:error, "Unexpected: #{leftovers}"}
      :error -> {:error, "Not an integer: #{string}"}
    end
  end

  def date_iso(string) do
    with {:ok, {year, month, day}} <- Calendar.ISO.parse_date(string) do
      Date.new(year, month, day)
    end
  end

  def date_slashes(string) do
    with {year, string} <- Integer.parse(string),
         {:ok, {_, string}} <- expect_prefix(string, "/"),
         {month, string} <- Integer.parse(string),
         {:ok, {_, string}} <- expect_prefix(string, "/"),
         {day, string} <- Integer.parse(string),
         {:ok, _} <- expect_end(string) do
      Date.new(year, month, day)
    end
  end

  defp expect_prefix(string, prefix) do
    string_size = byte_size(string)
    prefix_size = byte_size(prefix)

    if prefix_size > string_size do
      {:error, "Expected #{prefix}, got #{string}"}
    else
      string_prefix = binary_part(string, 0, prefix_size)

      if string_prefix == prefix do
        {:ok, {prefix, binary_part(string, prefix_size, string_size - prefix_size)}}
      else
        {:error, "Expected #{prefix}, got #{string_prefix}"}
      end
    end
  end

  defp expect_end(string) do
    if string == "" do
      {:ok, {}}
    else
      {:error, "Unexpected #{string}"}
    end
  end
end
