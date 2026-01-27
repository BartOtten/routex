# `Routex.Extension.LiveViewHooks`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension/live_view_hooks.ex#L1)

Attach LiveView hooks provided by Routex extensions.

This extension generates quoted functions to inject into LiveView's
lifecycle stages. The hooks are built from a set of supported lifecycle
callbacks provided by extensions.

The arguments given to these callbacks adhere to the official
specifications.

# `configure`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension/live_view_hooks.ex#L37)

```elixir
@spec configure(Routex.Types.opts(), Routex.Types.backend()) :: Routex.Types.opts()
```

Detect supported lifecycle callbacks in extensions and adds
them to `opts[:hooks]`.

Detects and registers supported lifecycle callbacks from other extensions.
Returns an updated keyword list with the valid callbacks accumulated
under the `:hooks` key.

**Supported callbacks:**
[handle_params: [:params, :uri, :socket], handle_event: [:event, :params, :socket], handle_info: [:msg, :socket], handle_async: [:name, :async_fun_result, :socket]]

# `create_shared_helpers`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension/live_view_hooks.ex#L64)

```elixir
@spec create_shared_helpers(
  Routex.Types.routes(),
  [Routex.Types.backend(), ...],
  Routex.Types.env()
) ::
  Routex.Types.ast()
```

Generates Routex' LiveView `on_mount/4` hook, which inlines the lifecycle
stage hooks provided by other extensions.

Returns  `on_mount/4` and an initial `handle_params/3`.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
