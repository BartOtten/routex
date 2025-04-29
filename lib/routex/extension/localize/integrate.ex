defmodule Routex.Extension.Localize.Integrate do
  @moduledoc false

  @fallback_locale "en"

  # Macro to prevent warnings about unknown / unloaded modules.
  defmacro auto_detect(locale_backend) do
    app_mod = lookup_app_module()

    quote generated: true do
      cond do
        Code.ensure_loaded?(Cldr) and unquote(locale_backend) ->
          {Cldr, Cldr, Cldr.known_locale_names(unquote(locale_backend)),
           Cldr.default_locale(unquote(locale_backend))}

        Code.ensure_loaded?(Cldr) ->
          {Cldr, Cldr, Cldr.known_locale_names(), Cldr.default_locale()}

        Code.ensure_loaded?(Gettext) ->
          backend =
            unquote(locale_backend) ||
              (unquote(app_mod) <> "Web.Gettext") |> String.to_atom()

          {Gettext, backend, Gettext.known_locales(backend), backend.__gettext__(:default_locale)}

        Code.ensure_loaded?(Fluent) ->
          backend =
            unquote(locale_backend) ||
              (unquote(app_mod) <> ".Fluent") |> String.to_atom()

          {Fluent, backend, Fluent.known_locales(backend), "en"}

        true ->
          {__MODULE__, [unquote(@fallback_locale)], unquote(@fallback_locale)}
      end
    end
  end

  @filename "mix.exs"

  # as there is no reliable way to use Project and Config functions, we
  # use Mix-file inspection instead.
  defp lookup_app_module do
    path =
      Mix.Project.app_path()
      |> Path.split()
      |> Enum.scan("/", &Path.join(&2, &1))
      |> Enum.reverse()
      |> Enum.find(fn
        "/" -> false
        path -> path |> Path.join(@filename) |> File.exists?()
      end)

    if path do
      content = path |> Path.join(@filename) |> File.read!()

      module =
        ~r/app: :(.*),/
        |> Regex.run(content, capture: :all_but_first)
        |> List.first()
        |> Macro.camelize()

      "Elixir." <> module
    else
      Routex.Utils.alert(
        "No locale backend detected",
        "Please set it explicitly in your Routex backend."
      )

      raise "No locale backend detected."
    end
  end
end
