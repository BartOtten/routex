defmodule MyAppWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use MyAppWeb, :controller
      use MyAppWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them prefix and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """
  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  def controller do
    quote do
      use Phoenix.Controller, namespace: MyAppWeb

      import Plug.Conn
      import MyAppWeb.Gettext

      unquote(verified_routes())
      unquote(routex_helpers())
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "test/support/my_app_web/templates",
        namespace: MyAppWeb

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_flash: 1, get_flash: 2, view_module: 1, view_template: 1]

      # Include shared imports and aliases for views
      unquote(view_helpers())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {MyAppWeb.LayoutView, :live}

      on_mount(MyAppWeb.MultiLangRouter.RoutexHelpers)

      unquote(view_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(view_helpers())
    end
  end

  def component do
    quote do
      use Phoenix.Component

      unquote(view_helpers())
    end
  end

  def router do
    quote do
      # Router Extension Framework
      use Routex.Router

      use Phoenix.Router, helpers: true

      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import MyAppWeb.Gettext
    end
  end

  defp view_helpers do
    quote do
      # Use all HTML functionality (forms, tags, etc)
      import Phoenix.HTML
      import Phoenix.HTML.Form
      use PhoenixHTMLHelpers

      # Import LiveView and .heex helpers (live_render, live_patch, <.form>, etc)
      import Phoenix.LiveView.Helpers
      import Phoenix.Component
      import MyAppWeb.LiveHelpers

      # Import basic rendering functionality (render, render_layout, etc)
      import Phoenix.View

      import MyAppWeb.ErrorHelpers
      import MyAppWeb.Gettext

      unquote(verified_routes())
      unquote(routex_helpers())
    end
  end

  defp routex_helpers do
    quote do
      def loc_route(_, _), do: "/fake/locced_route"
      import Phoenix.VerifiedRoutes, except: [sigil_p: 2]
      import MyAppWeb.MultiLangRouter.RoutexHelpers

      alias MyAppWeb.MultiLangRouter.Helpers, as: OriginalRoutes
      alias MyAppWeb.MultiLangRouter.RoutexHelpers, as: Routes

      alias MyAppWeb.MultiLangRoutes
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: MyAppWeb.Endpoint,
        router: MyAppWeb.Router,
        statics: MyAppWeb.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
