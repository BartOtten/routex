defmodule Routex.HelperFallbacks do
  @moduledoc """
  Provides fallback functions when `use`'d
  """
  defmacro __using__(_) do
    quote do
      @doc "Fallback for attrs/1 returning an empty map."
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

      @doc "Fallback for on_mount returning `{:cont, socket}` with unmodified socket"
      def on_mount(_key, _params, _session, socket), do: {:cont, socket}

      @doc "Fallback for plug/2 returning the conn unmodified"
      def plug(conn, _opts), do: conn

      defoverridable attrs: 1, on_mount: 4, plug: 2
    end
  end
end
