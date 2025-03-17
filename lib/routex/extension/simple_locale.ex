defmodule Routex.Extension.SimpleLocale do
  @moduledoc """
  Provides Liveview lifecycle hooks and Plug to set the runtime
  language or runtime locale using a call to `put_locale/{1,2}`.

   > #### Experimental {: .warning}
   > This module is experimental and may be subject to change

  Examples of supported packages:
  - Gettext
  - Fluent
  - Cldr

  ## Options
   - `:translation_backends` - A keyword list containing package-backend
     pairs used to invoke put_locale/2 for setting the language. This function
     accepts the attribute `:language` —falling back to :locale when necessary.
     Specifying "*" for a backend applies the value to all available backends.
   - `:locale_backends` - A keyword list containing package-backend pairs
     used to invoke put_locale/2 for setting the locale. This function accepts
     the attribute `:locale` —falling back to :language when necessary.
     Specifying "*" for a backend applies the value to all available backends.

  ## Example configuration
    ```diff
    # file lib/example_web/routex_backend.ex
    defmodule ExampleWeb.RoutexBackend do
      use Routex.Backend,
      extensions: [
        Routex.Extension.Attrs, # required
    +   Routex.Extension.SimpleLocale
    ],
    + translation_backends: [Gettext: "*"]
    + locale_backends: [Cldr: "*"]
    ```

    ## Result
    Gettext.put_locale(MyAppWeb.Gettext, attrs[:language] || attrs[:locale])
    Cldr.put_locale(MyAppWeb.Cldr, attrs[:locale] || attrs[:language])

    ## `Routex.Attrs`
    **Requires**
    - `:language` and/or `:locale`

    **Sets**
    - none

    ## Helpers
    plug(conn, opts, attrs) - inlined by Routex
    handle_params(params, url, socket, attrs) - inlined by Routex
  """

  @behaviour Routex.Extension

  alias Routex.Types, as: T

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
  @spec create_helpers(T.routes(), T.backend(), T.env()) :: T.ast()
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

    for config_key <- [:translation_backends, :locale_backends],
        !is_nil(config[config_key]),
        {package, backend} <- config[config_key],
        package = Module.concat([package]),
        Code.ensure_loaded!(package) do
      build_put_locale_ast(package, backend, config_key)
    end
  end

  defp build_put_locale_ast(package, "*", :locale_backends) do
    ensure_provided!(package, 1)

    quote do
      unquote(package).put_locale(attrs[:locale] || attrs[:language])
    end
  end

  defp build_put_locale_ast(package, backend, :locale_backends) do
    ensure_provided!(package, 2)

    quote do
      unquote(package).put_locale(unquote(backend), attrs[:locale] || attrs[:language])
    end
  end

  defp build_put_locale_ast(package, "*", :translation_backends) do
    ensure_provided!(package, 1)

    quote do
      unquote(package).put_locale(attrs[:language] || attrs[:locale])
    end
  end

  defp build_put_locale_ast(package, backend, :translation_backends) do
    ensure_provided!(package, 2)

    quote do
      unquote(package).put_locale(unquote(backend), attrs[:language] || attrs[:locale])
    end
  end

  defp ensure_provided!(package, arity) do
    function_exported?(package, :put_locale, arity) ||
      raise "#{package} does not provide put_locale/#{arity}"
  end
end
