# config Logger to only display >= warn as capture_log doesn't seem to work
Logger.configure(level: :warn)
ExUnit.start(capture_log: true)

defmodule RouterTestHelpers do
  @moduledoc false

  # return a route without certain metadata to make it determenistic
  def comparable_route(%{metadata: %{phoenix_live_view: {view, action, opts, map}}} = route) do
    new_plv = {view, action, Keyword.drop(opts, [:router]), Map.put(map, :vsn, nil)}

    route
    |> put_in([:metadata, :phoenix_live_view], new_plv)
    |> put_in([:metadata, :log], nil)
  end

  def comparable_route(route), do: put_in(route, [:metadata, :log], nil)
end

defmodule ListAssertions do
  # Courtesy of José Valim
  # https://elixirforum.com/t/assert-a-list-of-patterns-ignoring-order/46068/8
  @moduledoc false

  defmacro assert_unordered(patterns, expression) do
    patterns = if is_list(patterns), do: patterns, else: Macro.expand(patterns, __CALLER__)

    if(!is_list(patterns)) do
      raise ArgumentError, "#{inspect(patterns)} is not a list"
    end

    clauses =
      patterns
      |> Enum.with_index()
      |> Enum.flat_map(fn {pattern, index} ->
        quote do
          unquote(pattern) -> unquote(index)
        end
      end)

    clauses =
      clauses ++
        quote do
          _ -> :not_found
        end

    quote do
      ListAssertions.__assert_unordered__(
        unquote(Macro.escape(patterns)),
        unquote(expression),
        fn x -> case x, do: unquote(clauses) end
      )
    end
  end

  def __assert_unordered__(patterns, enum, fun) do
    result =
      Enum.reduce(enum, %{}, fn item, acc ->
        case fun.(item) do
          :not_found ->
            raise ArgumentError,
                  "#{inspect(item)} does not match any pattern: #{Macro.to_string(patterns)}"

          index when is_map_key(acc, index) ->
            raise ArgumentError,
                  "both #{inspect(item)} and #{inspect(acc[index])} match pattern: " <>
                    Macro.to_string(Enum.fetch!(patterns, index))

          index when is_integer(index) ->
            Map.put(acc, index, item)
        end
      end)

    if map_size(result) == length(patterns) do
      :ok
    else
      raise ArgumentError,
            "expected enumerable to have #{length(patterns)} entries, got: #{map_size(result)}"
    end
  end
end
