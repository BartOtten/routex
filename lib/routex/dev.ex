# credo:disable-for-this-file /\.Io/
defmodule Routex.Dev do
  @moduledoc """
  Provides functions to aid during development
  """

  @doc """
  `Macro.escape/1` and `IO.inspect/2` the given input. Options are
  passed through to `IO.inspect`. Returns the input.
  """
  def esc_inspect(ast, opts \\ [limit: :infinity, structs: false]) do
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
end