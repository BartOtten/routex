defmodule Routex.Processing do
  @moduledoc """
  This module provides everything needed to process Phoenix routes. It executes
  the `transform` callbacks from extensions to transform `Phoenix.Router.Route`
  structs and `create_helpers` callbacks to create one unified Helper module.

  **Powerful but thin**
  Although Routex is able to influence the routes in Phoenix applications in profound
  ways, the framework and its extensions are a surprisingly lightweight piece
  of compile-time middleware. This is made possible by the way router modules
  are pre-processed by `Phoenix.Router` itself.

  Prior to compilation of a router module, Phoenix Router registers all routes
  defined in the router module using the attribute `@phoenix_routes`. Each
  route is at that stage a `Phoenix.Router.Route` struct.

  Any route enclosed in a `preprocess_using` block has received a `:private`
  field in which Routex has put which Routex backend to use for that
  particular route. By enumerating the routes, we can process each route using
  the properties of this configuration and set struct values accordingly. This
  processing is nothing more than (re)mapping the Route structs' values.

  After the processing by Routex is finished, the `@phoenix_routes` attribute
  in the router is erased and re-populated with the list of mapped
  Phoenix.Router.Route structs.

  Once the router module enters the compilation stage, Routex is already out of
  the picture and route code generation is performed by Phoenix Router.
  """

  alias Routex.Attrs
  alias Routex.Types, as: T
  alias Routex.Utils
  @type extension_module :: module()
  @type helper_module :: module()

  @doc """
  Callback executed before compilation of a `Phoenix Router`. This callback is added
  to the `@before_compile` callbacks by `Routex.Router`.
  """
  @spec __before_compile__(T.env()) :: :ok
  def __before_compile__(env) do
    IO.write(["Start: Processing routes with ", inspect(__MODULE__), "\n"])
    execute_callbacks(env)
  end

  @doc false
  @spec helper_mod_name(module()) :: module
  def helper_mod_name(module), do: Module.concat([module, :RoutexHelpers])

  @doc """
  The main function of this module. Receives as only argument the environment of a
  Phoenix router module.
  """
  @spec execute_callbacks(T.env()) :: :ok
  def execute_callbacks(env),
    do: execute_callbacks(env, Utils.get_attribute(env.module, :phoenix_routes))

  @spec execute_callbacks(T.env(), T.routes()) :: :ok
  def execute_callbacks(env, routes) when is_list(routes) do
    helper_mod_name = helper_mod_name(env.module)

    backend_routes_callbacks =
      routes
      |> put_initial_attrs(helper_mod_name)
      |> group_by_backend()
      |> add_callbacks_map()

    {ast_per_extension, new_routes} =
      execute(backend_routes_callbacks, env)

    new_routes
    |> remove_build_info()
    |> write_routes(env)

    ast_per_extension
    |> generate_helper_ast(helper_mod_name)
    |> create_helper_module(helper_mod_name, env)

    IO.write(["End: ", inspect(__MODULE__), " completed route processing.", "\n"])
    :ok
  end

  defp debug?, do: System.get_env("ROUTEX_DEBUG") == "true"

  defp put_initial_attrs(routes, helper_mod_name) do
    routes
    |> Enum.with_index()
    |> Enum.map(fn {route, index} ->
      rtx = %{
        __origin__: route.path,
        __branch__: [index],
        __helper_mod__: helper_mod_name
      }

      overrides = Map.get(route.private, :rtx, %{})
      attrs = Map.merge(rtx, overrides)

      Attrs.merge(route, attrs)
    end)
  end

  defp group_by_backend(routes) do
    routes |> Enum.group_by(&Attrs.get(&1, :__backend__)) |> Map.drop([nil])
  end

  def add_callbacks_map(routes_per_backend) do
    Enum.map(routes_per_backend, fn {backend, routes} ->
      {backend, backend.callbacks(), routes}
    end)
  end

  defp execute(backend_routes_callbacks, env) do
    transformed_routes_per_backend = transform_routes_per_backend(backend_routes_callbacks, env)
    helpers_ast = generate_helpers_ast(transformed_routes_per_backend, env)
    new_routes = restore_routes_order(transformed_routes_per_backend)
    {helpers_ast, new_routes}
  end

  # Transformations

  def transform_routes_per_backend(backend_routes_callbacks, env) do
    Enum.map(backend_routes_callbacks, fn {backend, callbacks, routes} ->
      transformed_routes = apply_transform_callbacks(callbacks, routes, backend, env)
      {backend, callbacks, transformed_routes}
    end)
  end

  defp apply_transform_callbacks(callbacks, routes, backend, env) do
    Enum.reduce([:transform, :post_transform], routes, fn callback_name, acc ->
      extensions = callbacks[callback_name]
      apply_transform_callback(callback_name, extensions, acc, backend, env)
    end)
  end

  defp apply_transform_callback(callback_name, extensions, routes, backend, env) do
    Enum.reduce(extensions, routes, fn extension, inner_routes ->
      execute_callback(callback_name, backend, extension, [inner_routes, backend, env])
    end)
  end

  # AST Generation
  defp generate_helpers_ast(callback_name \\ :create_helpers, transformed_routes_per_backend, env) do
    Enum.flat_map(transformed_routes_per_backend, fn {backend, callbacks, routes} ->
      extensions = callbacks[callback_name]
      generate_helper_ast(callback_name, extensions, routes, backend, env)
    end)
  end

  defp generate_helper_ast(callback_name, extensions, routes, backend, env) do
    Enum.map(extensions, fn extension ->
      ast =
        callback_name
        |> execute_callback(backend, extension, [routes, backend, env])
        |> dedup_ast()

      :ok = Macro.validate(ast)

      {extension, ast}
    end)
  end

  defp restore_routes_order(processed_routes_per_backend) do
    processed_routes_per_backend
    |> Enum.flat_map(fn {_backend, _callbacks, routes} -> routes end)
    |> Enum.sort_by(&Attrs.get(&1, :__branch__))
  end

  @spec create_helper_module(T.ast(), helper_module, T.env()) ::
          {:module, module, binary, term}
  defp create_helper_module(ast, module, env) do
    IO.write(["Create or update helper module ", inspect(module), "\n"])
    Module.create(module, ast, env)
  end

  defp generate_helper_ast(ast_per_extension, module) do
    prelude =
      quote do
        require Logger
        use Routex.HelperFallbacks
      end

    helpers_ast =
      ast_per_extension
      |> Enum.map(fn {_ext, ast} -> ast end)
      |> dedup_ast()

    ast = [prelude, helpers_ast]

    if Application.fetch_env(:routex, :helper_mod_dir) != :error do
      sub_path = (module |> to_string() |> String.trim_leading("Elixir.")) <> ".ex"
      write_ast(ast, module, sub_path)
    end

    :ok = Macro.validate(ast)
    ast
  end

  defp write_ast(ast, module, sub_path) do
    dir = Application.fetch_env!(:routex, :helper_mod_dir)
    path = Path.join(dir, sub_path)

    Routex.Utils.print(__MODULE__, "Wrote AST of #{module} to #{path}")

    wrapped_ast =
      quote do
        defmodule unquote(module) do
          @moduledoc """
          This code is generated by Routex and is for inspection purpose only
          """

          unquote_splicing(ast)
        end
      end

    formatted_binary =
      wrapped_ast
      |> Macro.to_string()
      |> Code.format_string!()

    :ok = File.write(path, formatted_binary)
  end

  # prevent duplication of attributes, functions etc
  defp dedup_ast(ast) do
    ast
    |> List.wrap()
    |> List.flatten()
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp remove_build_info(routes) do
    Enum.map(routes, &Attrs.cleanup/1)
  end

  defp write_routes(routes, env) do
    Module.delete_attribute(env.module, :phoenix_routes)
    Module.register_attribute(env.module, :phoenix_routes, accumulate: true)
    Enum.each(routes, &Module.put_attribute(env.module, :phoenix_routes, &1))
  end

  @doc """
  Executes the specified callback for an extension and returns the result.
  """
  def execute_callback(callback, backend, extension_module, args) do
    postprint = [
      inspect(backend),
      " -> ",
      inspect(extension_module),
      ".",
      callback |> Atom.to_string() |> String.trim_leading(":"),
      "/",
      to_string(Enum.count(args))
    ]

    processing_print = "Executing: "
    complete_print = "Completed: "

    debug?() && IO.write([processing_print, postprint])
    result = apply(extension_module, callback, args)
    debug?() && IO.write(["\r", complete_print, postprint, "\n"])

    result
  end
end
