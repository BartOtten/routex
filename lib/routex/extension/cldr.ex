defmodule Routex.Extension.Cldr do
  @moduledoc ~S"""
  Adapter for projects using :ex_cldr. It generates the configuration
  for `Routex.Extension.Alternatives`.

  > #### Ejecting the CLDR extension {: .neutral}
  > Using the Cldr adapter provides the advantage of keeping your localized routes
  > in sync with the configuration of Cldr. The disadvantage is a lack of flexibility.
  > If you ever need more flexibility, you can [eject the Cldr extension](#module-eject-the-cldr-adapter).

  ## Interpolating Locale Data

  Interpolation is provided by `Routex.Extension.Interpolation`, which
  is able to use any `Routex.Attr` for interpolation into your routes.
  See it's documentation for additional options.

  When using this Cldr extension, the following interpolations are supported as they
  are set as `Routex.Attr`:

  * `locale` will interpolate the Cldr locale name
  * `locale_display` will interpolate the Cldr locale display name
  * `language` will interpolate the Cldr language name
  * `territory` will interpolate the Cldr territory code

  Some examples:
  ```elixir
  preprocess_using ExampleWeb.RoutexBackend do
    scope "/#{territory}/territory/" do
      get "/locale/pages/:page/#{locale}/", PageController, :show
      get "/language/#{language}/pages/:page", PageController, :show
    end
  end
  ```

  ## Configuration
  ```diff
  defmodule ExampleWeb.RoutexBackend do
  use Routex.Backend,
  extensions: [
    Routex.Extension.AttrGetters, # required
  + Routex.Extension.Cldr,
  + Routex.Extension.Alternatives,
  + Routex.Extension.Interpolation, #  when using routes with interpolation
  + Routex.Extension.Translations,  # when using translated routes
  + Routex.Extension.VerifiedRoutes
  ],
  + cldr_backend: MyApp.Cldr,
  + translations_backend: MyApp.Gettext,  #  when using translated routes
  + translations_domain: "routes",  #  when using translated routes
  + alternatives_prefix: false,  #  when using routes with interpolation
  + verified_sigil_routex: "~q", #  consider using ~p, see `Routex.Extension.VerifiedRoutes`
  ```

  ```diff
  defmodule ExampleWeb.Router
  # require your Cldr backend module before `use`ing the router.
  + require ExampleWeb.Cldr

  use ExampleWeb, :router

  import ExampleWeb.UserAuth
  ```

  When your application does not compile after adding this extension, force a
  recompile using `mix compile --force`.

  ## Pseudo result
   This extension injects `:alternatives` into your configuration.
   See the documentation of `Routex.Extension.Alternatives` to see
   more options and the pseudo result.

  ## Eject the Cldr adapter
  This extension abstracts away the configuration of `Routex.Extension.Alternatives`. You may want
  to customize things beyond what `Routex.Extension.Cldr` provides. When you eject, you copy
  the generated configuration into the Routex backend.

  In other words, instead of relying on the preconfigured “black box” provided by this extension, you
  now have full access to—and responsibility for—the configuration of `Routex.Extension.Alternatives`.

  #### Copy the generated configuration into your Routex backend**

  Call the `config/0` function on you backend (e.g. `ExampleWeb.RoutexBackend.config()`)
  in IEX. Copy the `alternatives: %{...}` section to your Routex backend.

  ```diff
  defmodule ExampleWeb.RoutexBackend do
  use Routex.Backend,
  extensions: [...],
  + alternatives: %{...}
  ```

  #### Remove references to Cldr

  ```diff
  defmodule ExampleWeb.RoutexBackend do
  use Routex.Backend,
  extensions: [
  -  Routex.Extension.Cldr,
  ],
  - cldr_backend: MyApp.Cldr,
  ```

  ```diff
  defmodule ExampleWeb.Router
  - require ExampleWeb.Cldr

  use ExampleWeb, :router

  import ExampleWeb.UserAuth
  ```

  ## `Routex.Attrs`
  **Requires**
  - none

  **Sets**
  - language
  - locale
  - locale_display
  - territory
  """

  @behaviour Routex.Extension
  require Logger

  def configure(config, _backend) do
    # causes a newline for output printed by Cldr
    IO.write("\n")

    backend = Keyword.get(config, :cldr_backend)
    root_attrs = backend.default_locale() |> get_attributes(backend)

    alternatives = %{
      "/" => %{
        attrs: root_attrs,
        branches: generate_branches(backend)
      }
    }

    Keyword.put(config, :alternatives, alternatives)
  end

  defp generate_branches(backend) do
    for locale <- get_locales(backend), into: %{} do
      locale_str = to_string(locale)
      slug = "/" <> locale_str

      {slug, %{attrs: get_attributes(locale, backend)}}
    end
  end

  defp get_attributes(locale, backend) do
    locale_module = Module.concat(backend, Locale)
    {:ok, info} = locale_module.new(locale)

    %{
      language: info.language,
      territory: info |> locale_module.territory_from_locale() |> to_string(),
      locale: to_string(info.cldr_locale_name),
      locale_name: display_name(locale, backend)
    }
  end

  defp get_locales(backend) do
    cldr_locales = backend.known_locale_names()
    gettext_locales = backend.known_gettext_locale_names()
    (cldr_locales ++ gettext_locales) |> Enum.uniq()
  end

  def display_name(locale, backend) do
    {:ok, result} =
      Module.concat(backend, LocaleDisplay).display_name(locale,
        locale: locale,
        compound_locale: false,
        prefer: :menu
      )

    result
  end
end
