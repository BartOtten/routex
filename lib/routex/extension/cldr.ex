defmodule Routex.Extension.Cldr do
  @moduledoc ~S"""
  Adapter for projects using :ex_cldr. It generates the configuration
  for `Routex.Extension.Alternatives`.


  ## Interpolating Locale Data

  Interpolation is provided by `Routex.Extension.Interpolation`, which
  is able to use any `Routex.Attr` for interpolation. See it's documentation
  for additional options.

  When using this Cldr extension, the following interpolations are supported as they
  are set as `Routex.Attr`:

  * `locale` will interpolate the Cldr locale name
  * `locale_display` will interpolate the Cldr locale display name
  * `language` will interpolate the Cldr language name
  * `territory` will interpolate the Cldr territory code

  Some examples are:
  ```elixir
  preprocess_using ExampleWeb.RoutexBackend do
    scope "/#{territory}/territory/" do
      get "/#{locale}/locale/pages/:page", PageController, :show
      get "/language/#{language}/pages/:page", PageController, :show
    end
  end
  ```

  ## Configuration
  ```diff
  defmodule ExampleWeb.RoutexBackend do
  use Routex.Backend,
  extensions: [
  + Routex.Extension.Cldr,
  + Routex.Extension.Alternatives,
  + Routex.Extension.Interpolation, #  when using routes with interpolation
  + Routex.Extension.Translations,  # when using translated routes
  + Routex.Extension.VerifiedRoutes,
    [...]
    Routex.Extension.AttrGetters
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

  ```
   alternatives: %{
    "/" => %{
      attrs: %{
        language: "en",
        locale: "en",
        territory: "US",
        locale_display: "English (United States)"
      },
      branches: %{
        "/en" => %{
          language: "en",
          locale: "en",
          territory: "US",
          locale_dispay: "English"
        },
        "/fr" => %{
          language: "fr",
          locale: "fr",
          territory: "FR",
          locale_display: "français"
        }
     }
   }

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

  def configure(config, _cm) do
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
      territory: to_string(info.territory),
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
