defmodule Mix.Tasks.Routex.InstallTest do
  use ExUnit.Case, async: true

  import Igniter.Test

  test "installing routex" do
    files = %{"lib/routex_web.ex" => routex_web(), "lib/routex_web/router.ex" => router()}

    [app_name: :routex, files: files]
    |> test_project()
    |> Igniter.compose_task("routex.install", [])
    |> assert_has_patch("lib/routex_web.ex", """
        | use Routex.Router
    """)
    |> assert_has_patch("lib/routex_web/router.ex", """
      | preprocess_using RoutexWeb.RoutexBackend do
    """)
    |> assert_has_patch("lib/routex_web/routex_backend.ex", """
      | use Routex.Backend,
      | extensions: [Routex.Extension.AttrGetters]
    """)
  end

  defp routex_web do
    """
    defmodule RoutexWeb do
      def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

      def router do
        quote do
          use Phoenix.Router, helpers: false
          import Plug.Conn
          import Phoenix.Controller
          import Phoenix.LiveView.Router
        end
      end

      def channel do
        quote do
          use Phoenix.Channel
        end
      end

      def controller do
        quote do
          use Phoenix.Controller,
            formats: [:html, :json],
            layouts: [html: VinjWeb.Layouts]

          use Gettext, backend: VinjWeb.Gettext
          import Plug.Conn
          unquote(verified_routes())
        end
      end

      def live_view do
        quote do
          use Phoenix.LiveView,  layout: {VinjWeb.Layouts, :app}
          unquote(html_helpers())
        end
      end

      def live_component do
        quote do
          use Phoenix.LiveComponent
          unquote(html_helpers())
        end
      end

      def html do
        quote do
          use Phoenix.Component
          import Phoenix.Controller,
            only: [get_csrf_token: 0, view_module: 1, view_template: 1]
          unquote(html_helpers())
        end
      end

      defp html_helpers do
        quote do
          use Gettext, backend: VinjWeb.Gettext
          import Phoenix.HTML
          import VinjWeb.CoreComponents
          alias Phoenix.LiveView.JS
          unquote(verified_routes())
        end
      end

      def verified_routes do
        quote do
          use Phoenix.VerifiedRoutes,
            endpoint: VinjWeb.Endpoint,
            router: VinjWeb.Router,
            statics: VinjWeb.static_paths()
        end
      end
    end
    """
  end

  defp router do
    """
    defmodule RoutexWeb.Router do
      use VinjWeb, :router

      pipeline :browser do
        plug :accepts, ["html"]
      end

      scope "/", VinjWeb do
        pipe_through :browser
      end
    end
    """
  end
end
