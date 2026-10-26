# `Routex.Attrs`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/attributes.ex#L1)

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

# `attrs_fun`

```elixir
@type attrs_fun() :: (map() -&gt; Enumerable.t())
```

# `container`

```elixir
@type container() ::
  Phoenix.Router.Route.t()
  | Phoenix.Socket.t()
  | Phoenix.LiveView.Socket.t()
  | Plug.Conn.t()
```

# `key`

```elixir
@type key() :: atom()
```

# `t`

```elixir
@type t() :: %{optional(key()) =&gt; value()}
```

# `update_fun`

```elixir
@type update_fun() :: (value() -&gt; value())
```

# `value`

```elixir
@type value() :: any()
```

# `cleanup`

```elixir
@spec cleanup(map() | container()) :: map() | container()
```

Removes non-private fields from attributes.

When given a plain map, it filters the map to include only keys starting with `"__"`.
When given a container (a map with a `:private` key), it filters the `:routex` attributes
in the private map.

# `get`

```elixir
@spec get(container(), key() | nil, value() | map()) :: value() | map()
```

Retrieves the value for `key` from the container's attributes, or returns `default`.

When no key is provided, returns the entire attributes map.

# `get!`

```elixir
@spec get!(container(), key(), String.t() | nil) :: value() | no_return()
```

Retrieves the value for `key` from the container's attributes.

Raises an error (with an optional custom message) if the key is not found.

# `merge`

```elixir
@spec merge(container(), keyword() | map()) :: container()
```

Merges the given value into the container's attributes.

The value can be either a list of key-value pairs or a map.

# `merge`

# `private?`

```elixir
@spec private?({atom(), any()} | atom()) :: boolean()
```

Returns true if the given key or attribute tuple represents a private attribute.

A private attribute is one whose name starts with `"__"`.

# `put`

```elixir
@spec put(container(), map()) :: container()
```

Replaces the container's attributes with the provided map.

# `put`

```elixir
@spec put(container(), key(), value()) :: container()
```

Assigns `value` to `key` in the container's attributes.

# `update`

```elixir
@spec update(container(), attrs_fun()) :: container()
```

Updates the container's attributes by applying the given function.

The function receives the current attributes map and must return an enumerable,
which is then converted into a new map.

# `update`

```elixir
@spec update(container(), key(), update_fun()) :: container()
```

Updates the value assigned to `key` in the container's attributes by applying the given function.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
