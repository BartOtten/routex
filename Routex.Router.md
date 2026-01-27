# `Routex.Router`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/router.ex#L1)

Provides macro (callbacks) to alter route definition before
compilation.

> #### `use Routex.Router` {: .info}
>
> When you `use Routex.Router`, the Routex.Router module will
> plug `Routex.Processing` between the definition of routes and the
> compilation of the router module. It also imports the `preprocess_using`
> macro which can be used to mark routes for Routex preprocessing using the
> Routex backend provided as first argument.

# `preprocess_using`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/router.ex#L65)
*macro* 

```elixir
@spec preprocess_using(Routex.Types.backend(), Routex.Types.opts(), [
  {:do, Routex.Types.ast()}
]) ::
  Routex.Types.ast()
```

Wraps each enclosed route in a scope, marking it for processing by Routex
using given `backend`. `opts` can be used to partially override the given
configuration.

Replaces interpolation syntax with a string for macro free processing by
extensions. Format: `[rtx.{binding}]`.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
