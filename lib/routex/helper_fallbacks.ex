# credo:disable-for-this-file Credo.Check.Design.DuplicatedCode

defmodule Routex.HelperFallbacks do
  @moduledoc """
  Provides fallback functions when `use`'d
  """
  defmacro __using__(_opts) do
    quote generated: true do
      @doc "Fallback for attrs/1 returning an empty map."
      @spec attrs(url :: binary()) :: no_return()
      def attrs(url),
        do:
          raise("""
          Routex Error: Missing required implementation of `attrs/1`.

          None of the enabled extensions provide an implementation for `attrs/1`.
          Please ensure that you have added and configured an extension that
          implements this function. For more details on how to set up the
          AttrGetters extension, see the documentation:

          https://hexdocs.pm/routex/Routex.Extension.AttrGetters.html
          """)

      @doc "Fallback for on_mount. Assigns :url"
      @spec on_mount(atom(), map(), map(), Phoenix.Socket.t()) :: {:cont, Phoenix.Socket.t()}
      def on_mount(_key, _params, _session, socket) do
        {:cont,
         Phoenix.LiveView.attach_hook(
           socket,
           :rtx_fallback,
           :handle_params,
           &__MODULE__.fallback_handle_params/3
         )}
      end

      @spec fallback_handle_params(map(), binary(), Phoenix.LiveView.Socket.t()) ::
              {:cont, Phoenix.LiveView.Socket.t()}
      def fallback_handle_params(_params, url, socket) do
        attrs = attrs(url)
        assign_mod = Routex.Utils.assign_module()

        socket =
          socket
          |> Routex.Attrs.merge(%{url: url, __branch__: attrs.__branch__})
          |> assign_mod.assign(url: url)
          |> assign_mod.assign(attrs[:assigns] || %{})

        {:cont, socket}
      end

      @doc "Fallback for call/2. Assigns :url"
      @spec call(Plug.Conn.t(), keyword()) :: Plug.Conn.t()
      def call(conn, _opts) do
        url =
          case {conn.request_path, conn.query_string} do
            {path, ""} -> path
            {path, query} -> "#{path}?#{query}"
          end

        attrs = attrs(url)

        conn
        |> Routex.Attrs.merge(%{url: url, __branch__: attrs.__branch__})
        |> Plug.Conn.assign(:url, url)
      end

      defmacro sigil_o(_path, _modifiers), do: raise_import()
      defmacro sigil_p(_path, _modifiers), do: raise_import()

      defp raise_import do
        raise("""
          Routex Error: Missing required implementation of `sigil_p/2`.

          Make sure you have at least one `process_using` block in your router. You might also
          have disabled the Verified Routes extension but still have to remove the import
          override in `routex_helpers`.

          https://hexdocs.pm/routex/Routex.Extension.VerifiedRoutes.html
        """)
      end

      defoverridable attrs: 1, on_mount: 4, call: 2, sigil_p: 2, sigil_o: 2
    end
  end
end
