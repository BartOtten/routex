defmodule Routex.Extension.Plugs do
  @moduledoc """
  Provides integration for plugs defined by Routex extensions.

  Detect extensions that implement supported plug callbacks. The valid plug
  callbacks are then collected and attached to the options under the `:plugs`
  key. Additionally, the module generates a Routex Plug hook that inlines the
  plugs provided by these extensions so that they are invoked in a single plug
  chain.
  """

  @behaviour Routex.Extension

  @storage_key __MODULE__
  @supported_callbacks [
    plug: [:conn, :opts]
  ]

  @doc """
  Detects and registers supported plug callbacks from other extensions.
  Returns an updated keyword list with the valid plug callbacks accumulated
  under the `:plugs` key.

  **Supported callbacks:**
  - `plug/3`: `Plug.Conn.call/2` with additional attributes argument
  """
  @impl Routex.Extension
  def configure(opts, _backend) do
    opts = Keyword.put_new(opts, :plugs, [])
    extensions = Keyword.get(opts, :extensions, [])

    Enum.reduce(extensions, opts, fn extension, acc ->
      valid_callbacks =
        Enum.filter(@supported_callbacks, fn {callback, params} ->
          function_exported?(extension, callback, length(params) + 1)
        end)

      Enum.reduce(valid_callbacks, acc, fn {callback, _params}, inner_acc ->
        update_in(inner_acc, [:plugs, callback], &[extension | List.wrap(&1)])
      end)
    end)
  end

  @impl Routex.Extension
  @doc false
  # Side-effect function used to register backend information.
  # This function registers the backend in the module attribute and returns the
  # unchanged routes. It is used by Routex during the transformation phase.
  def post_transform(routes, backend, env) do
    Module.register_attribute(env.module, @storage_key, accumulate: true)
    Module.put_attribute(env.module, @storage_key, backend)

    routes
  end

  @doc """
  Generates a plug hook for Routex that inlines plugs provided by other extensions.

  This helper function creates quoted expressions defining a plug function that
  encapsulates all the plug callbacks registered by Routex extension backends.
  """
  @impl Routex.Extension
  @spec create_helpers([Phoenix.Router.Route.t()], module(), Macro.Env.t()) :: Macro.output()
  def create_helpers(_routes, _backend, env) do
    backends = Module.get_attribute(env.module, @storage_key)

    Enum.map(backends, fn backend ->
      [{_callback, extensions}] = backend.config().plugs

      quote do
        @doc "Plug of Routex encapsulating extension plugs for #{unquote(backend)}"
        @spec plug(Plug.Conn.t(), list()) :: Plug.Conn.t()
        def plug(%{private: %{routex: %{__backend__: unquote(backend)}}} = conn, opts) do
          url =
            case {conn.request_path, conn.query_string} do
              {path, nil} -> path
              {path, query} -> "#{path}?#{query}"
            end

          attrs = attrs(url)
          conn = assign(conn, :url, url)

          Enum.reduce(unquote(extensions), conn, fn ext, conn ->
            # credo:disable-for-next-line
            apply(ext, :plug, [conn, opts, attrs])
          end)
        end
      end
    end)
  end
end
