defmodule Routex.Extension.Translations do
  @moduledoc """
  Enables users to enter URLs using localized terms which can enhance user engagement
  and content relevance.

  Extracts segments of a routes' path to a translations domain file (default: `routes.po`)
  for translation. At compile-time it combines the translated segments to transform routes.

  This extension expects either a `:language` attribute or a `:locale` attribute. When only
  `:locale` is provided it will try to extract the language from the locale tag. This algorithm is
  covers Alpha-2 and Alpha-3 codes (see:
  [ISO](https://datatracker.ietf.org/doc/html/rfc5646#section-2.2.1))

  ## Configuration
  ```diff
  defmodule ExampleWeb.RoutexBackend do
  use Routex.Backend,
  extensions: [
  + Routex.Extension.Translations
  ]
  + translations_backend: MyApp.Gettext,
  + translations_domain: "routes",
  ```

  ## Pseudo result
      # when translated to Spanish in the .po file
      # - products: producto
      # - edit: editar

      /products/:id/edit  ⇒ /producto/:id/editar

  ## `Routex.Attrs`
  **Requires**
  - language || locale

  **Sets**
  - none

  ## Use case(s)
  This extension can be combined with `Routext.Extension.Alternatives` to create
  multilingual routes.

  Use Alternatives to create new branches and provide a `:language` or `:locale` per branch and
  Translations to translate the alternative routes.

                          ⇒ /products/:id/edit                  language: "en"
      /products/:id/edit  ⇒ /nederland/producten/:id/bewerken   language: "nl"
                          ⇒ /espana/producto/:id/editar         language: "es"
  """

  @behaviour Routex.Extension

  alias Routex.Attrs
  require Logger

  @separator "/"
  @interpolate ":"
  @catch_all "*"
  @default_domain "routes"

  @impl Routex.Extension
  def configure(config, backend) do
    gettext_in_compilers? =
      Mix.Project.get!().project()
      |> Access.get(:compilers, [])
      |> Enum.member?(:gettext)

    auto_compile? =
      Version.match?(System.version(), ">= 1.14.0")

    unless auto_compile? or gettext_in_compilers?,
      do:
        Logger.warning(
          "When route translations are updated, run `mix compile --force [MyWebApp].Route"
        )

    unless Keyword.get(config, :translations_backend),
      do: raise("Expected `:translations_backend` to be set in #{to_string(backend)}")

    [{:translations_domain, Keyword.get(config, :translations_domain, @default_domain)} | config]
  end

  @impl Routex.Extension
  def transform(routes, config_backend, _env) do
    config = config_backend.config()

    for route <- routes do
      language = Attrs.get(route, :language)
      locale = Attrs.get(route, :locale)

      detected = language || detect_language!(locale, route)

      path =
        translate(route.path, detected, config.translations_backend, config.translations_domain)

      %{route | path: path}
    end
  end

  @impl Routex.Extension
  # creates gettext triggers so route segments are extracted into a translation file
  def create_helpers(routes, config_backend, _env) do
    config = config_backend.config()
    backend = config.translations_backend
    domain = config.translations_domain

    is_original_fn = &(&1 |> Attrs.get(:__branch__) |> List.last() == 0)

    uniq_segments =
      routes
      |> Enum.filter(is_original_fn)
      |> Enum.map(&Path.split(&1.path))
      |> List.flatten()
      |> Enum.uniq()

    prelude =
      quote do
        use Gettext, backend: unquote(backend)
      end

    triggers_ast =
      Enum.map(uniq_segments, fn
        @catch_all -> nil
        @interpolate <> _rest -> nil
        segment when not is_binary(segment) -> nil
        segment -> quote do: Gettext.dgettext(unquote(backend), unquote(domain), unquote(segment))
      end)

    [prelude | triggers_ast]
  end

  defp translate(path, locale, backend, domain)

  defp translate(path, locale, backend, domain) when is_binary(path) do
    Gettext.put_locale(backend, locale)

    path
    |> into_segment_list()
    |> translate_segments(locale, backend, domain)
    |> Enum.join()
  end

  defp into_segment_list(path), do: Regex.split(~r{(/)}, path, include_captures: true, trim: true)

  defp translate_segments(segments, locale, backend, domain) do
    Gettext.put_locale(backend, locale)
    Enum.map(segments, &translate_segment(&1, locale, backend, domain))
  end

  defp translate_segment(@separator, _loc, _back, _domain), do: @separator
  defp translate_segment(@catch_all, _loc, _back, _domain), do: @catch_all
  defp translate_segment(@interpolate <> _rest = segment, _loc, _back, _domain), do: segment
  defp translate_segment(segment, _loc, _back, _domain) when not is_binary(segment), do: segment

  defp translate_segment(segment, _loc, backend, domain),
    do: Gettext.dgettext(backend, domain, segment)

  defp detect_language!(<<lang::binary-size(2)>>, _), do: lang
  defp detect_language!(<<lang::binary-size(3)>>, _), do: lang
  defp detect_language!(<<lang::binary-size(2), ?-, _rest::binary>>, _), do: lang
  defp detect_language!(<<lang::binary-size(3), ?-, _rest::binary>>, _), do: lang
  defp detect_language!(<<lang::binary-size(2), ?_, _rest::binary>>, _), do: lang
  defp detect_language!(<<lang::binary-size(3), ?_, _rest::binary>>, _), do: lang

  defp detect_language!(nil, route) do
    backend = route |> Attrs.get(:backend) |> to_string()

    raise(
      "Routex backend `#{backend}` lists extension `#{__MODULE__}` but
 neither :language nor :locale was found in private.routex of route #{inspect(route, pretty: true)}."
    )
  end

  defp detect_language!(other, route) do
    raise(
      ":locale `#{other}` is a non supported format. Found in private.routex of route #{inspect(route, pretty: true)}."
    )
  end
end
