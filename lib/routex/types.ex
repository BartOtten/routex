defmodule Routex.Types do
  @moduledoc """
  Types shared by Routex core and extensions.
  """
  @type ast :: Macro.t() | [Macro.t()]
  @type backend :: Routex.Backend.t()
  @type config :: keyword()
  @type env :: Macro.Env.t()
  @type opts :: keyword()
  @type route :: Phoenix.Router.Route.t()
  @type routes :: [Phoenix.Router.Route.t()]
  @type attrs :: map()
end
