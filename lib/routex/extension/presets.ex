defmodule Routex.Extension.Preset do
  def merge(preset, config, module) do
    Keyword.merge(config, preset, fn
      :extensions, config, preset -> expand(module, preset, config)
      _key, user, _rtx -> user
    end)
  end

  # Replaces the name of the preset with the the presets' list of extensions.
  defp expand(preset_name, preset_extensions, extensions) do
    Enum.flat_map(extensions, fn
      ^preset_name -> preset_extensions
      x -> [x]
    end)
  end

  defmodule Minimal do
    @moduledoc """
    Routex preset which provides a basic set of extensions to build upon.
    """
    @behaviour Routex.Extension
    alias Routex.Extension.Preset

    @impl Routex.Extension
    def configure(config, _backend) do
      preset = [
        extensions: [
          Routex.Extension.AttrGetters,
          Routex.Extension.LiveViewHooks,
          Routex.Extension.Plugs
        ]
      ]

      Preset.merge(preset, config, __MODULE__)
    end
  end

  defmodule Alternatives do
    @moduledoc """
    Routex preset to generate alternative routes and seamlessly integrate them
    with existing codebases.

    The drop-in nature of the preset means you can enable alternative routes
    with minimal changes to your existing codebase.
    """
    @behaviour Routex.Extension
    alias Routex.Extension.Preset

    @impl Routex.Extension
    def configure(config, _backend) do
      preset = [
        extensions: [
          Preset.Minimal,
          Routex.Extension.AlternativeGetters,
          Routex.Extension.Alternatives,
          Routex.Extension.Assigns,
          Routex.Extension.RouteHelpers,
          Routex.Extension.VerifiedRoutes
        ],
        alternatives: %{
          "/" => %{
            attrs: %{locale: "en-150", display_name: "Global"},
            branches: %{
              "/branch_1" => %{
                attrs: %{locale: "en-150", display_name: "Branch 1"},
                branches: %{
                  "/branch_1_1" => %{attrs: %{locale: "en-150", display_name: "Branch 1 sub 1"}},
                  "/branch_1_2" => %{attrs: %{locale: "en-150", display_name: "Branch 1 sub 2"}}
                }
              },
              "/branch_2" => %{attrs: %{locale: "en-150", display_name: "Branch 2"}}
            }
          }
        },
        verified_sigil_routex: "~p",
        verified_sigil_phoenix: "~o",
        verified_url_routex: :url,
        verified_path_routex: :path
      ]

      Preset.merge(preset, config, __MODULE__)
    end
  end

  defmodule PhoenixI18n do
    @moduledoc """
    The preset automatically creates routes for multiple languages, Routex
    preset for Phoenix internationalization (i18n) and Phoenix localization
    (l10n). Designed to help developers effortlessly handle multiple languages
    and locales in their Phoenix applications.

    This preset generates alternative routes for different locales / languages
    and provides locale / language aware routing. Reducing the manual effort
    required to manage localized routes.

    The drop-in nature of the preset means you can enable localization with
    minimal changes to your existing codebase.
    """

    @behaviour Routex.Extension
    alias Routex.Extension.Preset

    @impl Routex.Extension
    def configure(config, _backend) do
      preset = [
        extensions: [
          Preset.Alternatives,
          Routex.Extension.PutLocale
        ],
        gettext_module: Module.concat(Mix.Phoenix.base(), Gettext)
      ]

      Preset.merge(preset, config, __MODULE__)
    end
  end

  defmodule PhoenixL10n do
    @moduledoc "Placeholder for Phoenix localization (l10n). Have a look at Routex.Extension.Preset.PhoenixI18n."
  end

  defmodule PhoenixI18nPlus do
    @moduledoc """
      Routex preset witch adds route translation on top of route localization / internationalization.

     Enables users to enter URLs using localized terms which can enhance user engagement and content relevance.
    """
    @behaviour Routex.Extension
    alias Routex.Extension.Preset

    @impl Routex.Extension
    def configure(config, _backend) do
      preset = [
        extensions: [
          Preset.PhoenixI18n,
          Routex.Extension.Translations
        ],
        gettext_module: Module.concat(Mix.Phoenix.base(), Gettext)
      ]

      Preset.merge(preset, config, __MODULE__)
    end
  end
end
