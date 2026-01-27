# `Routex.Extension`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension.ex#L1)

Specification for composable Routex extensions.

All callbacks are *optional*

See also: [Routex Extensions](EXTENSION_DEVELOPMENT.md)

# `configure`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension.ex#L17)
*optional* 

```elixir
@callback configure(Routex.Types.opts(), Routex.Types.backend()) :: Routex.Types.opts()
```

The `configure/2` callback is called in the first stage with the options
provided to `Routex` and the name of the Routex backend. It is expected to
return a new list of options.

# `create_helpers`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension.ex#L50)
*optional* 

```elixir
@callback create_helpers(
  Routex.Types.routes(),
  Routex.Types.backend(),
  Routex.Types.env()
) ::
  Routex.Types.ast()
```

The `create_helpers/3` callback is called in the last stage with a list of
routes belonging to a Routex backend, the name of the Routex backend and the
current environment. It is expected to return Elixir AST.

This can be used to create dedicated backend. As multiple backends may include
the extension, no catchall fallback is allowed. (see:
`create_shared_helpers/3`).

```elixir
def my_fun(%{arg: RoutexBackend.Default}), do: :foo
```

The AST is included in `MyAppWeb.Router.RoutexHelpers`.

# `create_shared_helpers`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension.ex#L81)
*optional* 

```elixir
@callback create_shared_helpers(
  Routex.Types.routes(),
  [Routex.Types.backend(), ...],
  Routex.Types.env()
) ::
  Routex.Types.ast()
```

The `create_shared_helpers/3` callback is called in the last stage. It differs
from `create_helpers/3` as it is called only once per extension with routes
combined of all backends using the extension.

This can be used to create cross-backend (combined) helpers or dedicated
backend helpers combined with an additional catch all function head.

```elixir
def my_fun(%{arg: RoutexBackend.Default}), do: :foo
def my_fun(%{arg: RoutexBackend.Other}), do: :bar
def my_fun(_), do: :biz
```

or

```elixir
def my_fun(socket) do
  ...some shared code...
  case socket_to_backend(socket) do
    %{arg: RoutexBackend.Default} ->  :foo
    %{arg: RoutexBackend.Other} ->  :bar
     _ ->  :biz
  end
end
```

The AST is included in `MyAppWeb.Router.RoutexHelpers`.

# `post_transform`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension.ex#L33)
*optional* 

```elixir
@callback post_transform(
  Routex.Types.routes(),
  Routex.Types.backend(),
  Routex.Types.env()
) ::
  Routex.Types.routes()
```

The `post_transform/1` callback is called in the third stage with a list of
routes belonging to a Routex backend. It is expected to return a list of
Phoenix.Router.Route structs almost identical to the input, only adding
`Routex.Attrs` -for own usage- is allowed.

# `transform`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension.ex#L25)
*optional* 

```elixir
@callback transform(Routex.Types.routes(), Routex.Types.backend(), Routex.Types.env()) ::
  Routex.Types.routes()
```

The `transform/3` callback is called in the second stage with a list of
routes belonging to a Routex backend, the name of the configuration model
and the current environment. It is expected to return a list of
Phoenix.Router.Route structs with flattened `Routex.Attrs`.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
