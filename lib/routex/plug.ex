defmodule Routex.Plug do
  def build(routes_per_backend, env) do
    for {backend, routes} <- routes_per_backend, backend != nil do
      create_callbacks(routes, backend, env) 
    end
    
     
    |> plug_ast(env)
    |> Routex.Dev.print_ast()
  end

  @spec plug_ast(plug_call_ast :: Macro.t(), env :: Macro.Env.t()) :: Macro.t()
  defp plug_ast(_plug_calls_ast, nil), do: nil

  defp plug_ast(plug_calls_ast, _env) do
    quote do
      def init(opts), do: opts
      unquote_splicing(plug_calls_ast)
    end
  end

  defp create_callbacks(_routes, nil, _env), do: nil

  defp create_callbacks(_routes, backend, env) do
    Code.ensure_loaded!(backend)
    helper_mod = Routex.Processing.helper_mod_name(env.module)

    ast =
      for ext <- backend.extensions() do
        if function_exported?(ext, :call, 2) do
          quote do
            conn = unquote(ext).unquote(:call)(conn, opts, attrs)
          end
        end
      end

    quote do
      def call(conn = %{private: %{routex: %{__backend__: unquote(backend)}}}, opts) do
        url = Map.get(conn, :request_path)
        attrs = unquote(helper_mod).attrs(url)
        conn = assign(conn, :url, url)

        unquote_splicing(ast  |> Enum.reject(&is_nil/1))

        conn
      end
    end
  end
end
