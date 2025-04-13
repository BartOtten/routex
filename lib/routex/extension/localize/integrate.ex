defmodule Routex.Extension.Localize.Integrate do
  @moduledoc false

  @fallback_locale "en"

  # Macro to prevent warnings about unknown / unloaded modules.
  defmacro auto_detect(locale_backend) do
    app_mod = lookup_app_module()

    quote generated: true do
      cond do
        Code.ensure_loaded?(Cldr) and unquote(locale_backend) ->
          {Cldr, Cldr.known_locale_names(unquote(locale_backend)),
           Cldr.default_locale(unquote(locale_backend))}

        Code.ensure_loaded?(Cldr) ->
          {Cldr, Cldr.known_locale_names(), Cldr.default_locale()}

        Code.ensure_loaded?(Gettext) ->
          backend =
            unquote(locale_backend) ||
              (unquote(app_mod) <> "Web.Gettext") |> String.to_existing_atom()

          {Gettext, Gettext.known_locales(backend), backend.__gettext__(:default_locale)}

        Code.ensure_loaded?(Fluent) ->
          backend =
            unquote(locale_backend) ||
              (unquote(app_mod) <> ".Fluent") |> String.to_existing_atom()

          {Fluent, Fluent.known_locales(backend), "en"}

        true ->
          {__MODULE__, [unquote(@fallback_locale)], unquote(@fallback_locale)}
      end
    end
  end

  defp lookup_app_module do
    suffix =
      Mix.Project.config()[:app]
      |> to_string()
      |> Macro.camelize()

    "Elixir." <> suffix
  end
end
