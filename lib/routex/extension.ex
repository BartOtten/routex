defmodule Routex.Extension do
  @moduledoc """
  Specification for composable Routex extensions.

  All callbacks are *optional*

  See also: [Routex Extensions](EXTENSION_DEVELOPMENT.md)
  """

  @type backend :: Routex.Backend.t()
  @type env :: Macro.Env.t()
  @type opts :: list
  @type routes :: [Phoenix.Router.Route.t()]
  @type params :: map
  @type url :: binary()
  @type socket :: Phoenix.Socket.t()
  @type conn :: Plug.Conn.t()
  @type attrs :: map

  @supported_livecycle_stages [
    handle_params: 4,
    handle_event: 4,
    handle_info: 4,
    handle_async: 4,
    after_render: 4
  ]

  @doc """
  The `configure/2` callback is called in the first stage with the options
  provided to `Routex` and the name of the Routex backend. It is expected to
  return a new list of options.
  """
  @callback configure(opts, backend) :: opts

  @doc """
  The `transform/3` callback is called in the second stage with a list of
  routes belonging to a Routex backend, the name of the configuration model
  and the current environment. It is expected to return a list of
  Phoenix.Router.Route structs with flattened `Routex.Attrs`.
  """
  @callback transform(routes, backend, env) :: routes

  @doc """
  The `post_transform/1` callback is called in the third stage with a list of
  routes belonging to a Routex backend. It is expected to return a list of
  Phoenix.Router.Route structs almost identical to the input, only adding
  `Routex.Attrs` -for own usage- is allowed.
  """
  @callback post_transform(routes, backend, env) :: routes

  for {stage, _arity} <- @supported_livecycle_stages do
    @doc ~s"""
    Callback for the `#{stage}` livecycle stage with the same name. Receives an
    additional argument `attrs` with `Routex.Attrs` of the current route. See
    also [Livecycle callbacks](#livecycle-callbacks)

    The callback should return either `{:cont, socket}` or `{:halt, socket}`
    """
    @callback unquote(stage)(params, url, socket, attrs) :: {:cont, %Phoenix.Socket{}}
  end

  @doc ~s"""
  Callback for the Plug pipeline. Receives an additional argument `attrs` with
  `Routex.Attrs` of the current route.  The callback should return `conn`
  """
  @callback plug(conn, opts, attrs) :: conn

  @doc """
  The `create_helpers/3` callback is called in the last stage with a list of
  routes belonging to a Routex backend, the name of the Routex backend and
  the current environment. It is expected to return Elixir AST.

  The AST is included in `MyAppWeb.Router.RoutexHelpers`.
  """
  @callback create_helpers(routes, backend, env) :: Macro.output()

  @optional_callbacks [configure: 2, transform: 3, post_transform: 3, create_helpers: 3, plug: 3] ++
                        @supported_livecycle_stages
end
