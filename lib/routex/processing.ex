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
    :handle_params,
    :handle_event,
    :handle_info,
    :handle_async,
    :after_render
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
    liveview_hooks_ast =
      for {backend, routes} <- processed_routes_per_backend_p2, backend != nil do
        create_liveview_hooks(routes, backend, env)
      end
      |> List.flatten()
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()

    on_mount_ast = on_mount_ast(liveview_hooks_ast, env)

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

  @spec create_liveview_hooks(routes, backend, Macro.Env.t()) :: Macro.t()
  defp create_liveview_hooks(_routes, nil, _env), do: nil

  defp create_liveview_hooks(_routes, backend, env) do
    Code.ensure_loaded!(backend)
    helper_mod = Routex.Processing.helper_mod_name(env.module)
    fn_ast = fn_ast(backend, :socket)

    for callback <- @supported_livecycle_stages do
      ast =
        for ext <- backend.extensions() do
          if callback_exists?(ext, callback, 3) do
            quote do
              {_, socket} = unquote(ext).unquote(callback)(params, url, socket, attrs)
            end
          end
        end
        |> Enum.reject(&is_nil/1)
        |> Enum.uniq()

      # TODO: This wont work for things like after_render callback
      if ast != [] || (callback == :handle_params && fn_ast != []) do
        quote context: Routex.Processing do
          socket =
            Phoenix.LiveView.attach_hook(
              socket,
              unquote(backend),
              unquote(callback),
              fn params, url, socket ->
                attrs = unquote(helper_mod).attrs(url)
                unquote_splicing(fn_ast)
                unquote_splicing(ast)
                {:cont, socket}
              end
            )
        end
      end
    end
  end

  @doc """
  Generates Abstract Syntax Tree (AST) to be included in Plug's `call`.

  **Special keys**
  1. `:conn`: converted to variable `conn`, which is provided by the `call` function head. Causes the result of the function to be assigned to `conn` in return.
  2. `:socket`, `:params`, or `:uri`: this function will not be included.
  3. key in `attrs`: converted to variable `attrs[key]`

  **Example**
  ```elixir
  attrs_into: [
  {Plug.Conn, :merge_assigns, [:conn, :assigns]},  # rule 1
  {Phoenix.Component, :assign, [:socket, :assigns]},  # rule 2
  {Gettext, :put_locale, [:locale]},  # rule 3
  ]
  ```

  **Pseudo result**
  ```elixir
  def call(conn, opts , attrs \\ %{}) do
     conn = Plug.Conn.merge_assigns(conn, attrs[:assigns])
     Gettext.put_locale(attrs[:locale])

     conn
  end
  ```

  """
  def plug_funcall_ast(backend) do
    fn_ast(backend, :conn)
  end

  @doc """
  Generates Abstract Syntax Tree (AST) to be included in a `handle_params` livecycle hook.

  **Special keys**
  1. `:socket`, `:params`, or `:uri`: converted to variables, which are provided by the `handle_params` function head. Causes the result of the function to be assigned to `socket` in return.
  2. `conn`: this function will not be included.
  3. key in `attrs`: converted to variable `attrs[key]`

  **Example**
  ```elixir
  attrs_into: [
  {Plug.Conn, :merge_assigns, [:conn, :assigns]},  # rule 1
  {Phoenix.Component, :assign, [:socket, :assigns]},  # rule 2
  {Gettext, :put_locale, [:locale]},  # rule 3
  ]
  ```

  **Pseudo result**
  ```elixir
  def handle_params(params, uri, socket , attrs \\ %{}) do
    socket = Phoenix.Component.assign(socket, attrs[:assigns])
    Gettext.put_locale(attrs[:locale])

    {:cont, socket}
  end
  ```
  """

  def on_mount_funcall_ast(backend) do
    fn_ast(backend, :socket)
  end

  defp fn_ast(backend, type) do
    config = backend.config()

    args_per_type = %{
      socket: MapSet.new([:params, :uri, :socket]),
      conn: MapSet.new([:conn])
    }

    config
    |> Map.get(:attrs_into, [])
    |> Enum.filter(fn {_mod, _fun, args} ->
      args_ms = MapSet.new(args)

      (type == :socket && MapSet.disjoint?(args_ms, args_per_type.conn)) ||
        (type == :conn && MapSet.disjoint?(args_ms, args_per_type.socket))
    end)
    |> Enum.map(fn {mod, fun, args} ->
      fun_args =
        Enum.map(args, fn arg ->
          cond do
            match?("Elixir." <> _, Atom.to_string(arg)) -> arg
            MapSet.member?(args_per_type[type], arg) -> Macro.var(arg, Routex.Processing)
            is_atom(arg) -> quote do: attrs[unquote(arg)] || unquote(arg)
          end
        end)

      if :socket in args || :conn in args do
        quote context: Routex.Processing do
          unquote(Macro.var(type, Routex.Processing)) =
            unquote(mod).unquote(fun)(unquote_splicing(fun_args))
        end
      else
        quote context: Routex.Processing do
          unquote(mod).unquote(fun)(unquote_splicing(fun_args))
        end
      end
    end)
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

    fn_ast = fn_ast(backend, :conn)

    ast =
      for ext <- backend.extensions() do
        if callback_exists?(ext, :call, 2) do
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

        unquote_splicing(fn_ast)
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

  defp on_mount_ast(liveview_hooks_ast, env) do
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
        unquote_splicing(liveview_hooks_ast)
        {:cont, socket}
      end

      def handle_params(_params, url, socket) do
        # as :helpers_mod is not yet set in the socket, we do manually
        attrs = unquote(module).attrs(url)

        socket =
          %{
            socket
            | private:
                Map.put(socket.private, :routex, %{
                  helpers_mod: unquote(module),
                  url: url,
                  __branch__: attrs.__branch__
                })
          }

        socket =
          Phoenix.Component.assign(
            socket,
            url: url,
            __branch__: attrs.__branch__
          )

        {:cont, socket}
      end
    end
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
    module.__info__(:functions)[callback] == arity
  end
end
