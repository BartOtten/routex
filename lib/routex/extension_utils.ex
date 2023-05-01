# credo:disable-for-this-file /\.Io/
defmodule Routex.ExtensionUtils do
  @moduledoc """
  Provides utility funtions for extension development.
  """

  @doc """
  `Macro.escape/1` and `IO.inspect/2` the given input. Options are
  passed through to `IO.inspect`. Returns the input.
  """
  def esc_inspect(ast, opts \\ []) do
    ast
    |> Macro.escape()
    |> IO.inspect(opts)
  end

  @doc """
  Helper function to inspect AST as formatted code. Returns the
  input.

  **Example**

      iex> ast = quote do: Map.put(my_map, :key, value)
      iex> inspect_ast(ast)
      Map.put(my_map, :key, value)
      ...actual AST...
  """
  @spec inspect_ast(ast :: Macro.t()) :: Macro.t()
  def inspect_ast(ast, env \\ __ENV__) do
    ast
    |> Macro.expand(env)
    |> Macro.to_string()
    |> Code.format_string!()
    |> IO.puts()

    ast
  end

  @doc """
  Returns the ast to get the last value in the order list
  """
  @spec get_helper_ast(caller :: Macro.Env.t()) :: Macro.output()
  def get_helper_ast(caller) do
    vars =
      caller.versioned_vars
      |> Enum.filter(fn
        {{var, _}, _} when var in [:socket, :conn, :assigns] ->
          true

        _other ->
          false
      end)
      |> Enum.map(fn {{var, _}, _} -> var end)

    cond do
      :socket in vars ->
        quote do
          var!(socket).private.routex.__order__ |> List.last()
        end

      :conn in vars ->
        quote do
          var!(conn).private.routex.__order__ |> List.last()
        end

      :assigns in vars ->
        quote do
          if is_map_key(var!(assigns), :conn) do
            var!(assigns).conn.private.routex.__order__ |> List.last()
          else
            var!(assigns).__order__ |> List.last()
          end
        end
    end
  end
end
