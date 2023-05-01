defmodule Routex.Attrs do
  @moduledoc """
    Provides an interface to access and update Routex attributes.

    Extensions can make use of `Routex.Attrs` values provided by Routex itself,
  Routex backends and other extensions. As those values are attributes to a
  route extension B can use values attributed to to a route by (pre)processing
  extension A.

    * To make the availability of the attributes as predictable as possible, Routex
    uses a flat structure.
    * Extension developers are encouraged to put as much information into the attributes
    as possible.
    * Extensions should add any fallback/default they might use themselves to the
    attributes.
  """

  @doc """
  Returns true when the provided key or attribute is private.
  """
  @spec is_private({atom, any} | atom) :: boolean()
  def is_private({key, _}), do: is_private(key)
  def is_private(key), do: key |> Atom.to_string() |> String.starts_with?("__")

  @doc """
  Removes non private fields from attrs. Input is either an opts map or a `Route`.
  """
  def cleanup(%Phoenix.Router.Route{} = route) do
    route
    |> update_in([Access.key!(:private), :routex], fn x -> Map.filter(x, &is_private/1) end)
  end

  def cleanup(meta) when is_map(meta) do
    Map.filter(meta, &is_private/1)
  end

  @doc """
  Updates the options of a `route` by applying given `function`.
  """
  def update(route, fun) do
    current = get(route)
    new = current |> fun.() |> Enum.into(%{})
    put(route, new)
  end

  @doc """
  Updates the value assigned to `key` of a `route`'s options by applying given `function`.
  """
  def update(route, key, fun) do
    current = get(route, key)
    new = fun.(current)
    put(route, key, new)
  end

  @doc """
  Merge `value` into `route`'s options.
  """

  def merge(route, value) when is_list(value),
    do: merge(route, Map.new(value))

  def merge(route, value) when is_map(value),
    do: Enum.reduce(value, route, fn {k, v}, acc -> put(acc, k, v) end)

  @doc """
  Assigns `value` to `route`'s options.
  """

  def put(route, value) when is_map(value),
    do: %{route | private: Map.put(route.private || %{}, :routex, value)}

  @doc """
  Assigns `value` to `key` in `route`'s options.
  """
  def put(route, key, value) when is_atom(key) and is_map_key(route.private, :routex),
    do: %{
      route
      | private: %{route.private | routex: Map.put(route.private.routex, key, value)}
    }

  def put(route, key, value) when is_atom(key),
    do: put(%{route | private: Map.put(route.private || %{}, :routex, %{})}, key, value)

  @doc """
  Get the value assigned to `key` from `route`'s options or return `default`. When no
  key is provided, the function returns all options.
  """
  def get(route, key \\ nil, default \\ nil)

  def get(route, nil, _default), do: route.private.routex

  def get(route, key, default)
      when is_atom(key) and is_map_key(route.private, :routex),
      do: Map.get(route.private.routex, key, default)

  def get(_route, key, default)
      when is_atom(key),
      do: default

  @doc """
  Get the value assigned to `key` from `route`'s options or raise if `key` not found. Accepts an optional
  custom `error_msg` as third argument
  """
  def get!(route, key, error_msg \\ nil) do
    error_msg = error_msg || "Key #{inspect(key)} not found in #{inspect(route.private.routex)}"

    try do
      Map.fetch!(route.private.routex, key)
    rescue
      _e -> reraise(error_msg, __STACKTRACE__)
    end
  end
end
