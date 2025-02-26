defmodule Routex.Processing do
  @moduledoc """
  This module provides everything needed to process Phoenix routes. It executes
  the `transform` callbacks from extensions to transform `Phoenix.Router.Route`
  structs and `create_helpers` callbacks to create one unified Helper module.

  **Powerful but thin**
  Although Routex is able to influence the routes in Phoenix applications in profound
  ways, the framework and it's extensions are a suprisingly lightweight piece
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
  alias Routex.Utils

  @type backend :: module
  @type extension_module :: module
  @type routes :: [Phoenix.Router.Route.t(), ...]

  @doc """
  Callback executed before compilation of a `Phoenix Router`. This callback is added
  to the `@before_compile` callbacks by `Routex.Router`.
  """
  @spec __before_compile__(Macro.Env.t()) :: :ok
  def __before_compile__(env) do
    IO.write(["Start: Processing routes with ", inspect(__MODULE__), "\n"])

    # Enable to get more descriptive error messages during development.
    # Causes compilation failure when enabled.
    wrap_in_task = System.get_env("ROUTEX_DEBUG") == "true"

    if wrap_in_task do
      Utils.alert(
        "Routex processing is wrapped in a task for debugging purposes. Compilation will fail"
      )

      task = Task.async(fn -> execute_callbacks(env) end)
      Task.await(task, :infinity)
    else
      execute_callbacks(env)
    end
  end

  @doc """
  The main function of this module. Receives as only argument the environment of a
  Phoenix router module.
  """
  @spec execute_callbacks(Macro.Env.t()) :: :ok
  def execute_callbacks(env) do
    routes =
      env.module
      |> Module.get_attribute(:phoenix_routes)
      |> put_initial_attrs(env)

    # grouping per config module allows extensions to use accumulated values.
    routes_per_backend = Enum.group_by(routes, &Attrs.get(&1, :__backend__))

    # phase 1: transform route structs
    processed_routes_per_backend_p1 =
      for {backend, routes} <- routes_per_backend do
        {backend, transform_routes(routes, backend, env)}
      end

    # phase 2: post transform route structs
    processed_routes_per_backend_p2 =
      for {backend, routes} <- processed_routes_per_backend_p1 do
        {backend, post_transform_routes(routes, backend, env)}
      end

    # phase 3: generate ast for helpers
    helpers_ast =
      for {backend, routes} <- processed_routes_per_backend_p2, backend != nil do
        create_helper_functions(routes, backend, env)
      end

    # restore routes order
    new_routes =
      processed_routes_per_backend_p2
      |> Enum.map(&elem(&1, 1))
      |> List.flatten()
      |> Enum.sort_by(&Attrs.get(&1, :__branch__))

    new_routes
    |> remove_build_info()
    |> write_routes(env)

    create_helper_module(helpers_ast, env)

    IO.write(["End: ", inspect(__MODULE__), " completed route processing.", "\n"])
    :ok
  end

  @spec put_initial_attrs([Phoenix.Router.Route.t()], Macro.Env.t()) :: [Phoenix.Router.Route.t()]
  defp put_initial_attrs(routes, env) do
    helper_module = helper_mod_name(env)

    routes
    |> Enum.with_index()
    |> Enum.map(fn {route, index} ->
      meta =
        Map.new()
        |> Map.put(:__origin__, route.path)
        |> Map.put(:__branch__, [index])
        |> Map.put(:__helper_mod__, helper_module)

      overrides = Map.get(route.private, :rtx, %{})
      attrs = Map.merge(meta, overrides)

      Attrs.merge(route, attrs)
    end)
  end

  @spec helper_mod_name(Macro.Env.t()) :: module
  @doc false
  def helper_mod_name(env), do: Module.concat([env.module, :RoutexHelpers])

  @spec transform_routes(routes, backend, Macro.Env.t()) :: routes
  defp transform_routes(routes, nil, _env), do: routes

  defp transform_routes(routes, backend, env) do
    Utils.ensure_compiled!(backend)

    for extension <- backend.extensions(), extension != [], reduce: routes do
      acc ->
        exec_when_defined(backend, extension, :transform, acc, [acc, backend, env])
    end
  end

  @spec post_transform_routes(routes, backend, Macro.Env.t()) :: routes
  defp post_transform_routes(routes, nil, _env), do: routes

  defp post_transform_routes(routes, backend, env) do
    Utils.ensure_compiled!(backend)

    for extension <- backend.extensions(), extension != [], reduce: routes do
      acc ->
        exec_when_defined(backend, extension, :post_transform, acc, [acc, backend, env])
    end
  end

  defp create_helper_functions(routes, backend, env) do
    Utils.ensure_compiled!(backend)

    for extension <- backend.extensions(), extension != [] do
      exec_when_defined(backend, extension, :create_helpers, nil, [
        routes,
        backend,
        env
      ])
    end
  end

  @spec create_helper_module(Macro.t(), Macro.Env.t()) ::
          {:module, module, binary, term}
  defp create_helper_module(extensions_ast, env) do
    module = helper_mod_name(env)
    IO.write(["Create or update helper module ", inspect(module), "\n"])

    stubs =
      for {fun, arity} <- [attrs: 1, on_mount: 4, plug: 2] do
        if not callback_exists?(extensions_ast, fun, arity) do
          Routex.Utils.print([
            inspect(module),
            ".",
            to_string(fun),
            "/",
            to_string(arity),
            " not found. Using stub."
          ])

          case fun do
            :attrs ->
              quote do
                @doc "Stub for attrs/1 returning an empty map."
                def attr(url), do: %{}
              end

            :on_mount ->
              quote do
                @doc "Stub for on_mount returning `{:cont, socket}` with unmodified socket"
                def on_mount(_key, _params, _session, socket), do: {:cont, socket}
              end

            :plug ->
              quote do
                @doc "Stub for plug/2 returning the conn unmodified"
                def plug(conn, _opts), do: conn
              end
          end
        end
      end

    prelude =
      quote do
        require Logger
      end

    ast = [prelude, stubs | extensions_ast] |> List.flatten() |> Enum.uniq()
    :ok = Macro.validate(ast)
    Module.create(module, ast, env)
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
  Checks if the `callback` is defined. When defined it executes
  the `callback` and returns the result , otherwise returns `default`.
  """
  def exec_when_defined(backend, extension_module, callback, default, args) do
    if callback_exists?(extension_module, callback, Enum.count(args)) do
      postprint = [
        inspect(backend),
        " ⇒ ",
        inspect(extension_module),
        ".",
        callback |> Atom.to_string() |> String.trim_leading(":"),
        "/",
        to_string(Enum.count(args))
      ]

      processing_print = "Executing: "
      complete_print = "Completed: "

      IO.write([processing_print, postprint])
      result = apply(extension_module, callback, args)
      IO.write(["\r", complete_print, postprint, "\n"])
      result
    else
      default
    end
  end

  defp callback_exists?(module, callback, arity) when is_atom(module) do
    module.__info__(:functions)[callback] == arity
  end

  defp callback_exists?(ast, function, arity) do
    ast
    |> Macro.prewalker()
    |> Enum.find_value(false, fn
      {:def, _meta1, [{^function, _meta2, args} | _rest]} -> length(args) == arity
      _other -> false
    end)
  end
end
