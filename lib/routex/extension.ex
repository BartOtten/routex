defmodule Routex.Extension do
  @moduledoc """
  Specification for composable Routex extensions.

  Optional callbacks:
  - configure
  - transform
  - post_transform
  - create_helpers

  See also: [Routex Extensions](EXTENSIONS.md)
  """

  @type backend :: Routex.Backend.t()
  @type env :: Macro.Env.t()
  @type opts :: list
  @type routes :: [Phoenix.Router.Route.t()]

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

  @doc """
  The `create_helpers/3` callback is called in the last stage with a list of
  routes belonging to a Routex backend, the name of the Routex backend and
  the current environment. It is expected to return Elixir AST.

  The AST is included in `MyAppWeb.Router.RoutexHelpers`.
  """
  @callback create_helpers(routes, backend, env) :: Macro.output()

  @optional_callbacks transform: 3, create_helpers: 3, configure: 2, post_transform: 3
end
