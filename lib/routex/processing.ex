# credo:disable-for-this-file Credo.Check.Refactor.IoPuts
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

  @supported_livecycle_stages [
    handle_params: [:params, :uri, :socket],
    handle_event: [:event, :params, :socket],
    handle_info: [:msg, :socket],
    handle_async: [:name, :async_fun_result, :socket]
  ]

  @doc """
  Callback executed before compilation of a `Phoenix Router`. This callback is added
  to the `@before_compile` callbacks by `Routex.Router`.
  """
  @spec __before_compile__(Macro.Env.t()) :: :ok
  def __before_compile__(env) do
    IO.puts(["Start: Processing routes with ", inspect(__MODULE__)])

    # Enable to get more descriptive error messages during development.
    # Causes compilation failure when enabled.
    wrap_in_task = debug?()

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

  defp debug? do
    System.get_env("ROUTEX_DEBUG") == "true"
  end

  @doc """
  The main function of this module. Receives as only argument the environment of a
  Phoenix router module.
  """
  @spec execute_callbacks(Macro.Env.t()) :: :ok
  def execute_callbacks(env) do
    routes = env.module |> Module.get_attribute(:phoenix_routes)

    # grouping per config module allows extensions to use accumulated values.
    routes_per_backend = group_by_backend(routes)

    # phase 1: configure (done elsewhere)

    # phase 2: transform route structs
    processed_routes_per_backend_p1 =
      for {backend, routes} <- routes_per_backend do
        {backend, transform_routes(routes, backend, env)}
      end

    # phase 3: post transform route structs
    processed_routes_per_backend_p2 =
      for {backend, routes} <- processed_routes_per_backend_p1 do
        {backend, post_transform_routes(routes, backend, env)}
      end

    # phase 4: generate AST for LiveView hooks and Plugs
    backends = Keyword.keys(processed_routes_per_backend_p2)

    liveview_hooks_ast_per_backend =
      create_liveview_hooks(@supported_livecycle_stages, backends, env)

    on_mount_ast = on_mount_ast(liveview_hooks_ast_per_backend, env)

    plug_calls_ast =
      for {backend, routes} <- processed_routes_per_backend_p2, backend != nil do
        create_plug_call(routes, backend, env)
      end
      |> List.flatten()
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()

    plug_ast = plug_ast(plug_calls_ast, env)

    # phase 5: generate AST for helper functions
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

    create_helper_module(helpers_ast, on_mount_ast, plug_ast, env)

    IO.puts(["End: ", inspect(__MODULE__), " completed route processing."])
    :ok
  end

  defp group_by_backend(routes) do
    routes
    |> Enum.with_index()
    |> Enum.map(&put_initial_attrs/1)
    |> Enum.group_by(&Attrs.get(&1, :__backend__))
  end

  defp put_initial_attrs({{route, exprs}, index}),
    do: {put_initial_attrs({route, index}), exprs}

  defp put_initial_attrs({route, index}) do
    meta =
      Map.new()
      |> Map.put(:__origin__, route.path)
      |> Map.put(:__branch__, [index])

    overrides = Map.get(route.private, :rtx, %{})
    values = Map.merge(meta, overrides)

    Attrs.merge(route, values)
  end

  @spec helper_mod_name(module) :: module
  @doc false
  def helper_mod_name(router), do: Module.concat([router, :RoutexHelpers])

  @spec transform_routes(routes, backend, Macro.Env.t()) :: routes
  defp transform_routes(routes, nil, _env), do: routes

  defp transform_routes(routes, backend, env) do
    Code.ensure_loaded!(backend)

    for extension <- backend.extensions(), extension != [], reduce: routes do
      acc ->
        exec_when_defined(backend, extension, :transform, acc, [acc, backend, env])
    end
  end

  @spec post_transform_routes(routes, backend, Macro.Env.t()) :: routes
  defp post_transform_routes(routes, nil, _env), do: routes

  defp post_transform_routes(routes, backend, env) do
    Code.ensure_loaded!(backend)

    for extension <- backend.extensions(), extension != [], reduce: routes do
      acc ->
        exec_when_defined(backend, extension, :post_transform, acc, [acc, backend, env])
    end
  end

  defp on_mount_ast(liveview_hooks_ast, env) do
    # backends = Keywords.keys(liveview_hooks_ast_per_backend)
    module = Routex.Processing.helper_mod_name(env.module)

    rtx_liveview_hook_ast =
      quote context: Routex.Processing do
        socket =
          Phoenix.LiveView.attach_hook(
            socket,
            unquote(__MODULE__),
            :handle_params,
            &unquote(module).handle_params/3
          )
      end

    quote do
      def on_mount(_key, params, session, socket) do
        unquote(rtx_liveview_hook_ast)
        unquote(liveview_hooks_ast)
        {:cont, socket}
      end

      def handle_params(_params, uri, socket) do
        # as :helpers_mod is not yet set in the socket, we do manually
        attrs = unquote(module).attrs(uri)

        socket =
          %{
            socket
            | private:
                Map.put(socket.private, :routex, %{
                  helpers_mod: unquote(module),
                  url: uri,
                  __branch__: attrs.__branch__
                })
          }

        socket =
          Phoenix.Component.assign(
            socket,
            url: uri,
            __branch__: attrs.__branch__
          )

        {:cont, socket}
      end
    end
  end

  defp build_cases(callback, callback_vars, cbs_per_backend) do
    for {backend, cbs} <- cbs_per_backend, cbs != [] do
      with_clauses =
        for ext <- cbs do
          quote do
            {:cont, socket} <- unquote(ext).unquote(callback)(unquote_splicing(callback_vars))
          end
        end

      with_statement =
        quote do
          with unquote_splicing(with_clauses) do
            {:cont, socket}
          end
        end

      quote do
        unquote(backend) -> unquote(with_statement)
      end
    end
    |> List.flatten()
  end

  defp build_functions(_callback, _hook_vars, [] = _cases, _helper_mod), do: nil

  defp build_functions(:handle_params, hook_vars, cases, helper_mod) do
    quote do
      fn unquote_splicing(hook_vars) ->
        attrs = unquote(helper_mod).attrs(uri)

        case attrs.__backend__ do
          [unquote_splicing(cases)]
        end
      end
    end
  end

  defp build_functions(_callback, hook_vars, cases, helper_mod) do
    quote do
      fn unquote_splicing(hook_vars) ->
        attrs = unquote(helper_mod).attrs(socket.private.routex.url)

        case attrs.__backend__ do
          [unquote_splicing(cases)]
        end
      end
    end
  end

  defp build_hook(callback, fun) do
    quote context: Routex.Processing do
      socket =
        Phoenix.LiveView.attach_hook(
          socket,
          __MODULE__,
          unquote(callback),
          unquote(fun)
        )
    end
  end

  # @spec create_liveview_hooks(map, backend) :: Macro.t()
  defp create_liveview_hooks(livecycle_stages, backends, env) do
    liveview_hooks_map =
      for {callback, args} = stage <- livecycle_stages, into: %{} do
        per_backend_result =
          for backend <- backends, backend != nil, into: %{} do
            extensions =
              for ext <- backend.extensions(),
                  function_exported?(ext, callback, length(args) + 1) do
                ext
              end

            {backend, extensions}
          end

        {stage, per_backend_result}
      end

    helper_mod = Routex.Processing.helper_mod_name(env.module)

    for {{callback, args}, cbs_per_backend} <- liveview_hooks_map do
      hook_vars = Enum.map(args, fn arg -> Macro.var(arg, Routex.Processing) end)
      callback_vars = hook_vars ++ [Macro.var(:attrs, Routex.Processing)]

      cases = build_cases(callback, callback_vars, cbs_per_backend)
      fun = build_functions(callback, hook_vars, cases, helper_mod)

      if fun, do: build_hook(callback, fun)
    end
  end

  @spec plug_ast(plug_call_ast :: Macro.t(), env :: Macro.Env.t()) :: Macro.t()
  defp plug_ast(_plug_calls_ast, nil), do: nil

  defp plug_ast(plug_calls_ast, _env) do
    quote do
      def init(opts), do: opts
      unquote_splicing(plug_calls_ast)
    end
  end

  defp create_plug_call(_routes, nil, _env), do: nil

  defp create_plug_call(_routes, backend, env) do
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
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()

    quote do
      def call(conn = %{private: %{routex: %{__backend__: unquote(backend)}}}, opts) do
        url = Map.get(conn, :request_path)
        attrs = unquote(helper_mod).attrs(url)

        unquote_splicing(ast)

        conn
      end
    end
  end

  defp create_helper_functions(routes, backend, env) do
    for extension <- backend.extensions(), extension != [] do
      exec_when_defined(backend, extension, :create_helpers, nil, [
        routes,
        backend,
        env
      ])
    end
  end

  @spec create_helper_module(Macro.t(), Macro.t(), Macro.t(), Macro.Env.t()) ::
          {:module, module, binary, term}
  defp create_helper_module(extensions_ast, on_mount_ast, plug_ast, env) do
    module = helper_mod_name(env.module)
    IO.puts(["Create or update helper module ", inspect(module)])

    # the on_mount callback relies on the availability of `attr/1`. As
    # we need to know if it's available upfront, we check the extension AST
    # to know if one of the extensions provided such helper.
    has_attr_func =
      extensions_ast
      |> Macro.prewalker()
      |> Enum.any?(&match?({:def, _meta1, [{:attrs, _meta2, _args} | _rest]}, &1))

    # instead of raising which makes testing hard, we print an error message.
    !has_attr_func &&
      Routex.Utils.alert([
        inspect(module),
        """
        .attrs/1` not found. Please include an extension providing
                 the `attrs/1` function (such as `Routex.Extension.AttrGetters`) in
                 the Routex backend extensions list.
        """
      ])

    prelude =
      quote do
        require Logger
      end

    ast = [prelude, extensions_ast, on_mount_ast, plug_ast] |> List.flatten() |> Enum.uniq()
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
      IO.puts(["\r", complete_print, postprint])
      result
    else
      default
    end
  end

  defp callback_exists?(module, callback, arity) do
    module.__info__(:functions)
    |> Keyword.get_values(callback)
    |> Enum.any?(&(&1 == arity))
  end
end
