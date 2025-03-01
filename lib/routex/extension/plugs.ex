defmodule Routex.Extension.Plugs do
  @moduledoc """
  Builds a Plug combining callbacks from extensions.
  """

  @storage_key __MODULE__

  def post_transform(routes, backend, env) do
    Module.register_attribute(env.module, @storage_key, accumulate: true)
    Module.put_attribute(env.module, @storage_key, {backend, routes})

    routes
  end

  @spec create_helpers([Phoenix.Router.Route.t()], module(), Macro.Env.t()) :: Macro.output()
  def create_helpers(_routes, _backend, env) do
    routes_per_backend =
      env.module
      |> Module.get_attribute(@storage_key)

    for {backend, routes} <- routes_per_backend, backend != nil do
      create_callbacks(routes, backend, env)
    end
    |> plug_ast(env)
  end

  @spec plug_ast(plug_call_ast :: Macro.t(), env :: Macro.Env.t()) :: Macro.t()
  defp plug_ast(_plug_calls_ast, nil), do: nil

  defp plug_ast(plug_calls_ast, _env) do
    quote do
      (unquote_splicing(plug_calls_ast))
    end
  end

  defp create_callbacks(_routes, nil, _env), do: nil

  defp create_callbacks(_routes, backend, env) do
    Code.ensure_loaded!(backend)
    helper_mod = Routex.Processing.helper_mod_name(env.module)

    ast =
      for ext <- backend.extensions(), function_exported?(ext, :plug, 2) do
        quote do
          conn = unquote(ext).unquote(:plug)(conn, opts, attrs)
        end
      end

    quote do
      @doc "Plug of Routex encapsulating extension plugs, Plug.call/2 behaviour"
      def plug(%{private: %{routex: %{__backend__: unquote(backend)}}} = conn, opts) do
        url = Map.get(conn, :request_path)
        attrs = unquote(helper_mod).attrs(url)
        conn = assign(conn, :url, url)

        unquote_splicing(ast)

        conn
      end
    end
  end
end
