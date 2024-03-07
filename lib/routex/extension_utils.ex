# credo:disable-for-this-file /\.Io/
defmodule Routex.ExtensionUtils do
  @moduledoc """
  Provides utility funtions for extension development.
  """
  require Logger

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
      :assigns in vars ->
        quote do
          case var!(assigns) do
            %{conn: %{private: %{routex: %{__order__: order}}}} ->
              List.last(order)

            %{__order__: order} ->
              List.last(order)
          end
        end

      :conn in vars ->
        quote do
          var!(conn).private.routex.__order__ |> List.last()
        end

      :socket in vars ->
        quote do
          case var!(socket) do
            %{private: %{routex: %{__order__: order}}} ->
              List.last(order)

            %{private: %{connect_info: %{private: %{routex: %{__order__: order}}}}} ->
              List.last(order)

            _ ->
              require Logger

              Logger.warning("""
              Using branching verified routes in `mount/3` is not supported.
              Please move the code to the `handle_params/3`.
              """)

              {:current_stacktrace, st} = Process.info(self(), :current_stacktrace)
              st |> tl |> Exception.format_stacktrace() |> Logger.warning()

              0
          end
        end

      ExUnit.Callbacks in caller.requires ->
        # IO.inspect(caller.versioned_vars)
        Logger.warning("No match for helper AST, set manual __order__")
        0

      true ->
        Logger.critical("Check HELPER AST")
        IO.inspect(caller.requires)
        0
    end
  end
end
