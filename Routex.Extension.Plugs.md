# `Routex.Extension.Plugs`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension/plugs.ex#L3)

Provides integration for plugs defined by Routex extensions.

Detect extensions that implement supported plug callbacks. The valid plug
callbacks are then collected and attached to the options under the `:plugs`
key. Additionally, the module generates a Routex Plug hook that inlines the
plugs provided by these extensions so that they are invoked in a single plug
chain.

# `configure`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension/plugs.ex#L32)

```elixir
@spec configure(Routex.Types.opts(), Routex.Types.backend()) :: Routex.Types.opts()
```

Detects and registers supported plug callbacks from other extensions.
Returns an updated keyword list with the valid plug callbacks accumulated
under the `:plugs` key.

**Supported callbacks:**
- `call/2`: `Plug.Conn.call/2`

# `create_shared_helpers`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension/plugs.ex#L60)

```elixir
@spec create_shared_helpers(
  Routex.Types.routes(),
  [Routex.Types.backend(), ...],
  Routex.Types.env()
) ::
  Routex.Types.ast()
```

Generates a plug hook for Routex that inlines plugs provided by other extensions.

This helper function creates quoted expressions defining a plug function that
encapsulates all the plug callbacks registered by Routex extension backends.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
