defmodule Routex.Extension.Translations do
  @moduledoc """
  Enables users to enter URLs using localized terms which can enhance user engagement
  and content relevance.

  Extracts segments of a routes' path to a translations domain file (default: `routes.po`)
  for translation. At compile-time it combines the translated segments to transform routes.

  ## Configuration
  ```diff
  defmodule ExampleWeb.RoutexBackend do
  use Routex,
  extensions: [
  + Routex.Extension.Translations
  ]
  + translations_backend: MyApp.Gettext,
  + translations_domain: "routes.po",
  ```

  ## Pseudo result
      # when translated to Spanish in the .po file
      # - products: producto
      # - edit: editar

      /products/:id/edit  ⇒ /producto/:id/editar

  ## `Routex.Attrs`
  **Requires**
  - locale

  **Sets**
  - none

  ## Use case(s)
  This extension can be combined with `Routext.Extension.Alternatives` to create
  multilingual routes.

  Use Alternatives to create new scopes and provide a `:locale` per scope and
  Translations to translate the alternative routes.

                          ⇒ /products/:id/edit                  locale = "en"
      /products/:id/edit  ⇒ /nederland/producten/:id/bewerken   locale = "nl"
                          ⇒ /espana/producto/:id/editar         locale = "es"
  """

  use Routex.Extension
  alias Routex.Attrs
  alias Routex.Path
  require Logger

  @interpolate ":"
  @catch_all "*"
  @default_domain "routes"

  @impl Routex.Extension
  def configure(config, _backend) do
    gt_in_compilers =
      Mix.Project.get!().project() |> Access.get(:compilers, []) |> Enum.member?(:gettext)

    unless Version.match?(System.version(), ">= 1.14.0") or gt_in_compilers do
      Logger.warn(
        "When route translations are updated, run `mix compile --force [MyWebApp].Route"
      )
    end

    unless Keyword.get(config, :translations_backend),
      do: raise("Expected :translations_backend to be set")

    [{:translations_domain, Keyword.get(config, :translations_domain, @default_domain)} | config]
  end

  @impl Routex.Extension
  def transform(routes, config_backend, _env) do
    config = config_backend.config()

    for route <- routes do
      locale =
        Attrs.get!(
          route,
          :locale,
          "#{route |> Attrs.get(:backend) |> to_string()} lists this extention but no
          :locale was found in private.routex of route #{inspect(Macro.escape(route))}."
        )

      path =
        translate(route.path, locale, config.translations_backend, config.translations_domain)

      %{route | path: path}
    end
  end

  defp translate(path, locale, backend, domain)

  defp translate(path, locale, backend, domain) when is_binary(path) do
    Gettext.put_locale(backend, locale)

    path
    |> Path.split()
    |> translate_segments(locale, backend, domain)
    |> Path.join()
  end

  defp translate_segments(segments, locale, backend, domain) do
    Gettext.put_locale(backend, locale)
    Enum.map(segments, &translate_segment(&1, locale, backend, domain))
  end

  defp translate_segment("/" <> _rest = segment, locale, backend, domain) do
    translate(segment, locale, backend, domain)
  end

  defp translate_segment(@catch_all, _loc, _back, _domain), do: @catch_all
  defp translate_segment(@interpolate <> _rest = segment, _loc, _back, _domain), do: segment
  defp translate_segment(segment, _loc, _back, _domain) when not is_binary(segment), do: segment

  defp translate_segment(segment, _loc, backend, domain),
    do: Gettext.dgettext(backend, domain, segment)
end
