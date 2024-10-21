defmodule Routex.Route do
  @moduledoc """
  Function for working with Phoenix Routes
  """
  alias Phoenix.Router.Route
  alias Routex.Attrs

  @default_nesting_offset 0

  @doc """
  Returns the nesting level of an (ancestor) route. By default
  the parent. This can be adjusted by providing an negative depth offset.
  """
  def get_nesting(route, offset \\ @default_nesting_offset) when offset <= 0 do
    slice_end = -2 + offset
    route |> Attrs.get(:__branch__) |> Enum.slice(0..slice_end//1)
  end

  @doc """
  Returns routes grouped by nesting level of an (ancestor) route. By default
  groups by parent. This can be adjusted by providing an negative depth offset
  """
  def group_by_nesting(routes, offset \\ @default_nesting_offset) when offset <= 0 do
    slice_end = -2 + offset
    root = &(&1 |> Attrs.get(:__branch__) |> Enum.slice(0..slice_end//1))

    routes
    |> Enum.group_by(root)
  end

  @doc """
  Returns routes grouped by the combination of method and path of an (ancestor)
  route. By default groups by parent. This can be adjusted by providing a
  negative depth offset.
  """
  def group_by_method_and_path(routes, offset \\ @default_nesting_offset) when offset <= 0 do
    routes
    |> group_by_nesting(offset)
    |> Enum.map(fn {_nesting, groutes} -> {{hd(groutes).verb, hd(groutes).path}, groutes} end)
    |> Map.new()
  end

  @doc """
  Compatibility wrapper around `Phoenix.Router.Route.exprs`
  """

  # Using apply to prevent compilation problems due to non existing
  # function definition

  # credo:disable-for-lines:10 Credo.Check.Refactor.Apply
  @spec exprs(Route.t(), Macro.Env.t()) :: map
  def exprs(route, env) do
    if Kernel.function_exported?(Route, :exprs, 2) do
      forwards = env.module |> Module.get_attribute(:phoenix_forwards)
      apply(Route, :exprs, [route, forwards])
    else
      apply(Route, :exprs, [route])
    end
  end
end
