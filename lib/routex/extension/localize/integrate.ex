defmodule Routex.Extension.Localize.Integrate do
  @moduledoc false

  @fallback_locale "en"

  # Macro to prevent warnings about unknown / unloaded modules.
  defmacro auto_detect(locale_backend) do
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
              unquote((lookup_app_module() <> "Web.Gettext") |> String.to_atom())

          {Gettext, backend, Gettext.known_locales(backend), backend.__gettext__(:default_locale)}

        Code.ensure_loaded?(Fluent) ->
          backend =
            unquote(
              locale_backend ||
                (lookup_app_module() <> ".Fluent") |> String.to_atom()
            )

          {Fluent, backend, Fluent.known_locales(backend), "en"}

        true ->
          {__MODULE__, __MODULE__, [unquote(@fallback_locale)], unquote(@fallback_locale)}
      end
    end
  end

  @filename "mix.exs"

  # as there is no reliable way to use Project and Config functions, we
  # use Mix-file inspection instead.
  def lookup_app_module do
    with path when is_binary(path) <- get_mix_path(),
         content <- path |> Path.join(@filename) |> File.read!(),
         module <-
           ~r/app: :(.*),/
           |> Regex.run(content, capture: :all_but_first)
           |> List.first()
           |> Macro.camelize() do
      "Elixir." <> module
    else
      false ->
        Routex.Utils.alert(
          "No locale backend detected",
          "Please set it explicitly in your Routex backend."
        )

        raise "No locale backend detected."
    end
  end

  def get_mix_path do
    Mix.Project.app_path()
    |> Path.split()
    |> Enum.scan("/", &Path.join(&2, &1))
    |> Enum.reverse()
    |> Enum.find(fn
      "/" -> false
      path -> path |> Path.join(@filename) |> File.exists?()
    end)
  rescue
    _error -> false
  end
end
