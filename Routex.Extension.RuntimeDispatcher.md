# `Routex.Extension.RuntimeDispatcher`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension/runtime_dispatcher.ex#L1)

The `Routex.Extension.RuntimeDispatcher` enables the dynamic dispatching of
functions to external libraries or modules during the Plug pipeline and
LiveView's `handle_params`. This dispatching is configured using a list of
`{module, function, arguments}` tuples and leverages attributes from
`Routex.Attrs` at runtime.

This is particularly useful for integrating with libraries that handle
internationalization or localization, such as:

* Gettext - Set language for translations
* Fluent - Set language for translations
* Cldr - Set locale for the Cldr suite

> #### In combination with... {: .neutral}
> This extension dispatches functions with values from `Routex.Attrs` during
> runtime. These attributes are typically set by other extensions such as:
>
> * `Routex.Extension.Alternatives` (compile time)
> * `Routex.Extension.Localize.Phoenix` (compile time and runtime)
> * `Routex.Extension.Localize.Phoenix.Routes` (compile time)
> * `Routex.Extension.Localize.Phoenix.Runtime` (runtime)

### Options

* `dispatch_targets` - A list of `{module, function, arguments}` tuples. Any argument
  that is a list starting with `:attrs` is transformed into `get_in(attrs(), rest)`.
  Defaults to `[{Gettext, :put_locale, [[:attrs, :runtime, :language]]}]` for zero-config
  integration with a default Phoenix app.

### Example Configuration

````elixir
defmodule MyApp.RoutexBackend do
  use Routex.Backend,
    extensions: [
      Routex.Extension.Attrs,
      Routex.Extension.RuntimeDispatcher
    ],
    dispatch_targets: [
      # Dispatch Gettext locale from detected :language attribute
      {Gettext, :put_locale, [[:attrs, :runtime, :language]]},

      # Dispatch CLDR locale from detected :locale attribute
      {Cldr, :put_locale, [MyApp.Cldr, [:attrs, :runtime, :locale]]}
    ]
end
````

## Error Handling

The extension validates all dispatch configurations during compilation to
ensure the specified modules and functions exist:

* Checks if the module is loaded
* Verifies the function exists with the correct arity
* Raises a compile-time error if validation fails

Example error:

````elixir
** (RuntimeError) Gettext does not provide put_locale/1.
 Please check the value of :dispatch_targets in the Routex backend module
````

## `Routex.Attrs`
**Requires**
- none

**Sets**
- none

## Helpers
`dispatch_targets(attrs :: T.attrs) :: :ok`

# `call`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension/runtime_dispatcher.ex#L113)

A plug fetching the attributes from the connection and calling helper function `dispatch_targets/1`

# `handle_params`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension/runtime_dispatcher.ex#L122)

A Phoenix Lifecycle Hook fetching the attributes from the socket and calling helper function `dispatch_targets/1`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
