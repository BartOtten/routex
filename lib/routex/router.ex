defmodule Routex.Router do
  @moduledoc """
  Provides macro (callbacks) to alter route definition before
  compilation.

  > #### `use Routex.Router` {: .info}
  >
  > When you `use Routex.Router`, the Routex.Router module will
  > plug `Routex.Processing` between the definition of routes and the
  > compilation of the router module. It also imports the `preprocess_using`
  > macro which can be used to mark routes for Routex preprocessing using the
  > Routex backend provided as first argument.
  """

  alias Routex.Types, as: T

  @supported_types [
    :get,
    :post,
    :put,
    :patch,
    :delete,
    :options,
    :connect,
    :trace,
    :head,
    :live,
    :resources
  ]

  @unsupported_types []

  @default_types [
    :get,
    :head,
    :options
  ]

  @spec __using__(T.opts()) :: T.ast()
  defmacro __using__(_options) do
    quote do
      @before_compile Routex.Processing
      import unquote(__MODULE__), only: [preprocess_using: 2, preprocess_using: 3]
      defdelegate routex(conn, opts), to: Routex.Processing.helper_mod_name(__MODULE__), as: :call
    end
  end

  @doc false
  def __supported_types__, do: @supported_types
  @doc false
  def __unsupported_types__, do: @unsupported_types
  @doc false
  def __default_types__, do: @default_types

  @doc """
  Wraps each enclosed route in a scope, marking it for processing by Routex
  using given `backend`. `opts` can be used to partially override the given
  configuration.

  Replaces interpolation syntax with a string for macro free processing by
  extensions. Format: `[rtx.{binding}]`.
  """

  @spec preprocess_using(T.backend(), T.opts(), do: T.ast()) :: T.ast()
  defmacro preprocess_using(backend, opts \\ [], do: ast) do
    backend = Macro.expand_once(backend, __CALLER__)
    Routex.Utils.ensure_compiled!(backend)

    Macro.postwalk(ast, fn
      node = {route_method, _route_opts, _route_args} when route_method in @supported_types ->
        wrap_in_scope(node, backend, opts)

      {{:., _meta, [Kernel, :to_string]}, _meta2, [{binding, _meta3, _args3}]} ->
        quote do: "[rtx.#{unquote(binding)}]"

      node ->
        node
    end)
  end

  # Routes within a `preprocess_using` block are wrapped in a scope which
  # provides the most uniform interface to pass extra information to the
  # different types of routes due to the variation in their arguments.

  defp wrap_in_scope(node, backend, opts) do
    quote do
      scope path: "/",
            private: %{
              routex:
                Map.new([
                  {:__backend__, unquote(backend)}
                  | unquote(opts)
                ])
            } do
        unquote(node)
      end
    end
  end
end
