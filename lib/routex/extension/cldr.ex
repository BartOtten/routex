defmodule Routex.Extension.Cldr do
  @moduledoc """
  Adapter for projects using :ex_cldr. It generates the configuration
  for `Routex.Extension.Alternatives`.

  ## Configuration
  ```diff
  defmodule ExampleWeb.RoutexBackend do
  use Routex.Backend,
  extensions: [
  + Routex.Extension.Cldr
  ]
  + cldr_backend: MyApp.Cldr
  ```

  ```diff
  defmodule ExampleWeb.Router
  + require ExampleWeb.Cldr
  ```

  ## Pseudo result
   This extension injects configuration for `Routex.Extension.Alternatives`. See the documentation
   of that extension to see the result.

  ```
   alternatives: %{
    "/" => %{
      attrs: %{
        language: "en",
        locale: "en",
        territory: "US",
        locale_name: "English (United States)"
      },
      branches: %{
        "/en" => %{
          language: "en",
          locale: "en",
          territory: "US",
          locale_name: "English"
        },
        "/fr" => %{
          language: "fr",
          locale: "fr",
          territory: "FR",
          locale_name: "français"
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
  - locale_name
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

      {slug, get_attributes(locale, backend)}
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
