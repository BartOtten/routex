# `Routex.Processing`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/processing.ex#L1)

This module provides everything needed to process Phoenix routes. It executes
the `transform` callbacks from extensions to transform `Phoenix.Router.Route`
structs and `create_helpers` callbacks to create one unified Helper module.

**Powerful but thin**
Although Routex is able to influence the routes in Phoenix applications in profound
ways, the framework and its extensions are a surprisingly lightweight piece
of compile-time middleware. This is made possible by the way router modules
are pre-processed by `Phoenix.Router` itself.

Prior to compilation of a router module, Phoenix Router registers all routes
defined in the router module using the attribute `@phoenix_routes`. Each
route is at that stage a `Phoenix.Router.Route` struct.

Any route enclosed in a `preprocess_using` block has received a `:private`
field in which Routex has put which Routex backend to use for that
particular route. By enumerating the routes, we can process each route using
the properties of this configuration and set struct values accordingly. This
processing is nothing more than (re)mapping the Route structs' values.

After the processing by Routex is finished, the `@phoenix_routes` attribute
in the router is erased and re-populated with the list of mapped
Phoenix.Router.Route structs.

Once the router module enters the compilation stage, Routex is already out of
the picture and route code generation is performed by Phoenix Router.

# `extension_module`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/processing.ex#L34)

```elixir
@type extension_module() :: module()
```

# `helper_module`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/processing.ex#L35)

```elixir
@type helper_module() :: module()
```

# `__before_compile__`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/processing.ex#L42)

```elixir
@spec __before_compile__(Routex.Types.env()) :: :ok
```

Callback executed before compilation of a `Phoenix Router`. This callback is added
to the `@before_compile` callbacks by `Routex.Router`.

# `add_callbacks_map`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/processing.ex#L140)

# `execute_callback`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/processing.ex#L313)

Executes the specified callback for an extension and returns the result.

# `execute_callbacks`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/processing.ex#L56)

```elixir
@spec execute_callbacks(Routex.Types.env()) :: :ok
```

The main function of this module. Receives as only argument the environment of a
Phoenix router module.

# `execute_callbacks`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/processing.ex#L67)

```elixir
@spec execute_callbacks(Routex.Types.env(), Routex.Types.routes()) :: :ok
```

# `transform_routes_per_backend`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/processing.ex#L160)

---

*Consult [api-reference.md](api-reference.md) for complete listing*
