defmodule Routex.Extension.Preset do
  @doc """
   Replaces the name of the preset with the the presets' list of extensions.
  """
  def expand(preset_name, preset_extensions, extensions) do
    Enum.flat_map(extensions, fn
      ^preset_name -> preset_extensions
      x -> [x]
    end)
  end

  def merge(preset, config, module) do
    Keyword.merge(config, preset, fn
      :extensions, config, preset -> expand(module, preset, config)
      _key, user, _rtx -> user
    end)
  end

  defmodule Minimal do
    @moduledoc """
      Provides the minimal set of extensions for Routex to work.
    """
    @behaviour Routex.Extension
    alias Routex.Extension.Preset

    @impl Routex.Extension
    def configure(config, _backend) do
      preset = [
        extensions: [
          Routex.Extension.AttrGetters,
          Routex.Extension.Plugs,
          Routex.Extension.LiveViewHooks
        ]
      ]

      Preset.merge(preset, config, __MODULE__)
    end
  end

  defmodule Alternatives do
    @moduledoc """
      Provides a Routex preset to work with alternatives Routes
      while acting like a drop-in solution.
    """
    @behaviour Routex.Extension
    alias Routex.Extension.Preset

    @impl Routex.Extension
    def configure(config, _backend) do
      preset = [
        extensions: [
          Routex.Extension.Preset.Minimal,
          Routex.Extension.Alternatives,
          Routex.Extension.AlternativeGetters,
          Routex.Extension.Assigns,
          Routex.Extension.VerifiedRoutes,
          Routex.Extension.RouteHelpers
        ],
        verified_sigil_routex: "~p",
        verified_sigil_phoenix: "~o",
        verified_url_routex: :url,
        verified_path_routex: :path
      ]

      Preset.merge(preset, config, __MODULE__)
    end
  end

  defmodule LocalizedRoutes do
    @moduledoc """
      Routex preset to work with localized routes
    """
    @behaviour Routex.Extension
    alias Routex.Extension.Preset

    @impl Routex.Extension
    def configure(config, _backend) do
      preset = [
        extensions: [
          Routex.Extension.Preset.Alternatives,
          Routex.Extension.Interpolation
        ]
      ]

      Preset.merge(preset, config, __MODULE__)
    end
  end

  defmodule FullLocalization do
    @moduledoc """
      Routex preset to enable full l10n / i18n applications.
    """
    @behaviour Routex.Extension
    alias Routex.Extension.Preset

    @impl Routex.Extension
    def configure(config, _backend) do
      preset = [
        extensions: [
          Routex.Extension.Preset.LocalizedRoutes,
          Routex.Extension.Translations
        ],
        gettext_module: Module.concat(Mix.Phoenix.base(), Gettext)
      ]

      Preset.merge(preset, config, __MODULE__)
    end
  end
end
