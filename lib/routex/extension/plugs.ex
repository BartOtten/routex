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

  alias Routex.Route
  alias Routex.Types, as: T

  @supported_callbacks [
    call: [:conn, :opts]
  ]

  @doc """
  Detects and registers supported plug callbacks from other extensions.
  Returns an updated keyword list with the valid plug callbacks accumulated
  under the `:plugs` key.

  **Supported callbacks:**
  - `call/2`: `Plug.Conn.call/2`
  """
  @impl Routex.Extension
  @spec configure(T.opts(), T.backend()) :: T.opts()
  def configure(opts, _backend) do
    opts = Keyword.put_new(opts, :plugs, [])
    extensions = Keyword.get(opts, :extensions, [])

    Enum.reduce(extensions, opts, fn extension, acc ->
      valid_callbacks =
        Enum.filter(@supported_callbacks, fn {callback, params} ->
          function_exported?(extension, callback, length(params))
        end)

      Enum.reduce(valid_callbacks, acc, fn {callback, _params}, inner_acc ->
        update_in(
          inner_acc,
          [:plugs, callback],
          &(&1 |> List.wrap() |> List.insert_at(-1, extension) |> Enum.uniq())
        )
      end)
    end)
  end

  @doc """
  Generates a plug hook for Routex that inlines plugs provided by other extensions.

  This helper function creates quoted expressions defining a plug function that
  encapsulates all the plug callbacks registered by Routex extension backends.
  """
  @impl Routex.Extension
  @spec create_helpers(T.routes(), T.backend(), T.env()) :: T.ast()
  def create_helpers(routes, _backend, _env) do
    backends = Route.get_backends(routes)

    Enum.map(backends, fn backend ->
      plugs = Map.get(backend.config(), :plugs, [])
      call_extensions = Keyword.get(plugs, :call, [])

      quote do
        @doc "Plug of Routex encapsulating extension plugs for #{unquote(backend)}"
        @spec call(Plug.Conn.t(), list()) :: Plug.Conn.t()
        def call(%{private: %{routex: %{__backend__: unquote(backend)}}} = conn, opts) do
          url =
            case {conn.request_path, conn.query_string} do
              {path, ""} -> path
              {path, query} -> "#{path}?#{query}"
            end

          attrs = attrs(url)
          conn = conn |> Routex.Attrs.merge(attrs) |> assign(:url, url)

          Enum.reduce(unquote(call_extensions), conn, fn ext, conn ->
            # credo:disable-for-next-line
            apply(ext, :call, [conn, opts])
          end)
        end
      end
    end)
  end
end
