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

  @backends :backends

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

  @spec __using__(opts :: list) :: Macro.output()
  defmacro __using__(_options) do
    caller_module = __CALLER__.module

    Module.register_attribute(caller_module, @backends, [])

    quote bind_quoted: [caller_module: caller_module] do
      @before_compile Routex.Processing

      import Routex.Router, only: [preprocess_using: 2, preprocess_using: 3]

      defdelegate routex(conn, opts),
        to: Routex.Processing.helper_mod_name(caller_module),
        as: :plug
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

  @spec preprocess_using(module, opts :: list, do: ast :: Macro.t()) :: ast :: Macro.t()
  defmacro preprocess_using(backend, opts \\ [], do: ast) do
    backend = Macro.expand_once(backend, __CALLER__)
    router = __CALLER__.module

    Routex.Utils.ensure_compiled!(backend)

    # instead of accumulating (possible causing duplicate values) we add the
    # backend to the current list and replace the attribute with the result.
    current_backends = Module.get_attribute(router, @backends, [])
    new_backends = Enum.uniq([backend | current_backends])
    Module.put_attribute(router, @backends, new_backends)

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
