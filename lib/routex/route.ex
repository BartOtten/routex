defmodule Routex.Route do
  @type t :: %__MODULE__{
          private: %{:routex => %{__branch__: list(), __origin__: binary}, optional(any) => any}
        }

  defstruct %Phoenix.Router.Route{private: %{routex: %{__branch__: [], __origin__: nil}}}
            |> Map.from_struct()
            |> Keyword.new()

  @moduledoc """
  Function for working with Routex augmented Phoenix Routes
  """
  alias Routex.Attrs
  alias __MODULE__

  @default_nesting_offset 0

  @doc """
  Returns a `Routex.Route`
  """
  @spec new(Phoenix.Router.Route.t()) :: t()
  def new(%Phoenix.Router.Route{} = route) do
    new = route |> Map.from_struct() |> ensure_routex()
    struct(__MODULE__, new)
  end

  @doc """
  Returns a `Routex.Route`
  """
  @spec to_phx(t()) :: Phoenix.Router.Route.t()
  def to_phx(%Routex.Route{} = route) do
    new = route |> Map.from_struct()
    struct(Phoenix.Router.Route, new)
  end

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

  # @doc """
  # Returns routes grouped by the combination of method and path of an (ancestor)
  # route. By default groups by parent. This can be adjusted by providing a
  # negative depth offset.
  # """
  def group_by_method_and_path(routes, offset \\ @default_nesting_offset) when offset <= 0 do
    routes
    |> group_by_nesting(offset)
    |> Enum.map(fn {_nesting, groutes} -> {{hd(groutes).verb, hd(groutes).path}, groutes} end)
    |> List.flatten()
    |> Map.new()
  end

  @doc "Returns routes grouped by the combination of method and origin path"
  def group_by_method_and_origin(routes) do
    routes |> Enum.group_by(&{&1.verb, Routex.Attrs.get!(&1, :__origin__)})
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

  # Ensures that the container has a :routex key in its :private map.
  defp ensure_routex(%{private: %{}} = route_sock_or_conn) do
    update_in(route_sock_or_conn, [Access.key(:private, %{})], fn private ->
      Map.put_new(private, :routex, %{})
    end)
  end

  defp ensure_routex(%{private: nil} = route_sock_or_conn) do
    route_sock_or_conn
    |> Map.put(:private, %{})
    |> ensure_routex()
  end
end
