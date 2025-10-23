defmodule Routex.Attrs do
  @moduledoc """
  Provides an interface to access and update Routex attributes
  in routes, sockets, or connections (hereinafter `containers`).

  Extensions can make use of `Routex.Attrs` values provided by Routex itself,
  Routex backends, and other extensions. As these values are attributes to a route,
  one extension can use values set by another.

  Other extensions set `Routex.Attrs` (see each extension’s documentation for the
  list of attributes they set). To define custom attributes for routes, see
  `Routex.Extension.Alternatives`.

  * To ensure predictable availability, Routex uses a flat structure.
  * Extension developers are encouraged to embed as much contextual information as possible.
  * Extensions should add any fallback/default they might use to the attributes.
  """

  @type container ::
          Phoenix.Router.Route.t()
          | Phoenix.Socket.t()
          | Phoenix.LiveView.Socket.t()
          | Plug.Conn.t()
  @type key :: atom()
  @type value :: any()
  @type attrs_fun :: (map() -> Enumerable.t())
  @type update_fun :: (value() -> value())
  @type t :: %{optional(key) => value}

  @doc """
  Returns true if the given key or attribute tuple represents a private attribute.

  A private attribute is one whose name starts with `"__"`.
  """
  @spec private?({atom(), any()} | atom()) :: boolean()
  def private?({key, _v}), do: private?(key)

  def private?(key) when is_atom(key) do
    key |> Atom.to_string() |> String.starts_with?("__")
  end

  @doc """
  Removes non-private fields from attributes.

  When given a plain map, it filters the map to include only keys starting with `"__"`.
  When given a container (a map with a `:private` key), it filters the `:routex` attributes
  in the private map.
  """
  @spec cleanup(map() | container()) :: map() | container()
  def cleanup(route_sock_or_conn) when is_struct(route_sock_or_conn) do
    route_sock_or_conn
    |> ensure_routex()
    |> update_in(
      [Access.key!(:private), :routex],
      &Map.filter(&1, fn kv -> private?(kv) end)
    )
  end

  def cleanup(meta) when is_map(meta) do
    Map.filter(meta, &private?/1)
  end

  @doc """
  Updates the container's attributes by applying the given function.

  The function receives the current attributes map and must return an enumerable,
  which is then converted into a new map.
  """
  @spec update(container(), attrs_fun()) :: container()
  def update(route_sock_or_conn, fun) when is_function(fun, 1) do
    current = get(route_sock_or_conn)
    new = current |> fun.() |> Enum.into(%{})
    put(route_sock_or_conn, new)
  end

  @doc """
  Updates the value assigned to `key` in the container's attributes by applying the given function.
  """
  @spec update(container(), key(), update_fun()) :: container()
  def update(route_sock_or_conn, key, fun) when is_function(fun, 1) do
    current = get(route_sock_or_conn, key)
    new = fun.(current)
    put(route_sock_or_conn, key, new)
  end

  @doc """
  Merges the given value into the container's attributes.

  The value can be either a list of key-value pairs or a map.
  """
  @spec merge(container(), keyword() | map()) :: container()
  def merge(route_sock_or_conn, value) when is_list(value) do
    merge(route_sock_or_conn, Map.new(value))
  end

  def merge(route_sock_or_conn, value) when is_map(value) do
    Enum.reduce(value, route_sock_or_conn, fn {k, v}, acc ->
      put(acc, k, v)
    end)
  end

  def merge(route_sock_or_conn, key, value)
      when (is_atom(key) and is_map(value)) or is_list(value) do
    update(route_sock_or_conn, key, fn
      nil -> value
      old when is_map(old) -> Map.merge(old, value)
      old when is_list(old) -> old ++ value
    end)
  end

  @doc """
  Replaces the container's attributes with the provided map.
  """
  @spec put(container(), map()) :: container()
  def put(route_sock_or_conn, value) when is_map(value) do
    route_sock_or_conn
    |> ensure_routex()
    |> put_in([Access.key!(:private), :routex], value)
  end

  @doc """
  Assigns `value` to `key` in the container's attributes.
  """
  @spec put(container(), key(), value()) :: container()
  def put(route_sock_or_conn, key, value) when is_atom(key) do
    route_sock_or_conn
    |> ensure_routex()
    |> update_in([Access.key!(:private), :routex], &Map.put(&1, key, value))
  end

  @doc """
  Retrieves the value for `key` from the container's attributes, or returns `default`.

  When no key is provided, returns the entire attributes map.
  """
  @spec get(container(), key() | nil, value() | map()) :: value() | map()
  def get(route_sock_or_conn, key \\ nil, default \\ nil)

  def get(route_sock_or_conn, nil, default) do
    case route_sock_or_conn.private do
      %{routex: attrs} -> attrs
      _other -> default || %{}
    end
  end

  def get(route_sock_or_conn, key, default) when is_atom(key) do
    case route_sock_or_conn.private do
      %{routex: attrs} -> Map.get(attrs, key, default)
      _other -> default
    end
  end

  @doc """
  Retrieves the value for `key` from the container's attributes.

  Raises an error (with an optional custom message) if the key is not found.
  """
  @spec get!(container(), key(), String.t() | nil) :: value() | no_return()
  def get!(route_sock_or_conn, key, error_msg \\ nil) when is_atom(key) do
    attrs =
      case route_sock_or_conn.private do
        %{routex: attrs} -> attrs
        _other -> %{}
      end

    case Map.fetch(attrs, key) do
      {:ok, value} ->
        value

      :error ->
        msg =
          error_msg ||
            "Key #{inspect(key)} not found in #{inspect(attrs)}"

        raise(msg)
    end
  end

  # Ensures that the container has a :routex key in its :private map.
  @spec ensure_routex(container()) :: container()
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
