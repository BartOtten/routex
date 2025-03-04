defmodule Routex.Extension.PutLocale do
  # credo:disable-for-lines:15
  @module_config_map [
    Gettext: :translations_backend,
    Fluent: :translations_backend,
    Cldr: :cldr_backend
  ]
  @supported_packages Keyword.keys(@module_config_map)

  @moduledoc """
  Provides Liveview lifecycle hooks and Plug to put the locale
  in any of #{Enum.join(@supported_packages, ", ")} when installed
  and configured.
  """

  @behaviour Routex.Extension

  @doc """
  Hook attached to the `handle_params` stage in the LiveView life cycle. Inlined by Routex.
  """
  def handle_params(_params, _url, socket, attrs \\ %{}) do
    attrs.__helper_mod__.put_locale(attrs)
    {:cont, socket}
  end

  @doc """
  Plug added to the Conn lifecycle. Inlined by Routex.
  """
  def plug(conn, _opts, attrs \\ %{}) do
    attrs.__helper_mod__.put_locale(attrs)
    conn
  end

  @impl Routex.Extension
  def create_helpers(_routes, backend, _env) do
    ast = build_ast(backend)

    quote do
      def put_locale(attrs) do
        (unquote_splicing(ast))
      end
    end
  end

  defp build_ast(backend) do
    config = backend.config() |> Map.from_struct()

    for {module, config_key} <- @module_config_map,
        module = Module.concat([module]),
        Code.ensure_compiled(module),
        function_exported?(module, :put_locale, 1),
        !is_nil(config[config_key]) do
      build_put_locale_ast(module, config, config_key)
    end
  end

  defp build_put_locale_ast(module, config, config_key) when module in [Cldr] do
    quote do
      unquote(module).put_locale(unquote(config[config_key]), attrs[:locale] || attrs[:language])
    end
  end

  defp build_put_locale_ast(module, config, config_key) when module in [Gettext, Fluent] do
    quote do
      unquote(module).put_locale(unquote(config[config_key]), attrs[:language] || attrs[:locale])
      unquote(module).put_locale(attrs[:language] || attrs[:locale])
    end
  end
end
