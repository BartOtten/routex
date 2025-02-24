defmodule Routex.LiveViewHook do
  @moduledoc """
  Provides helper functions to build and attach Routex LiveView hooks.

  This module generates quoted functions to plug Routex’s routing logic into LiveView's
  lifecycle (e.g. on_mount and handle_params). The hooks are built from a set of supported
  lifecycle stages and per-backend extensions.
  """

  @supported_livecycle_stages [
    handle_params: [:params, :uri, :socket],
    handle_event: [:event, :params, :socket],
    handle_info: [:msg, :socket],
    handle_async: [:name, :async_fun_result, :socket]
  ]

  @doc """
  Builds Routex LiveView hooks.

  Returns a list of quoted expressions defining `on_mount/4` and `handle_params/3`.

  ## Examples

      iex> Routex.LiveViewHook.build(%{BackendA => ...}, env)
      [on_mount_ast, handle_params_ast]
  """
  @spec build(map(), term()) :: Macro.output()
  def build(routes_per_backend, env) do
    helper_mod = Routex.Processing.helper_mod_name(env.module)

    rtx_hook = build_routex_hook(helper_mod)

    extension_hooks =
      create_liveview_hooks(routes_per_backend, @supported_livecycle_stages, helper_mod)

    on_mount_ast = add_to_on_mount([rtx_hook | extension_hooks])
    handle_params_ast = build_handle_params(helper_mod)

    [on_mount_ast, handle_params_ast]
  end

  # Returns a quoted definition for `handle_params/3` that assigns Routex attributes to the socket.
  @spec build_handle_params(module()) :: Macro.output()
  defp build_handle_params(helper_mod) do
    quote do
      @spec handle_params(map(), binary(), Phoenix.LiveView.Socket.t()) ::
              {:cont, Phoenix.LiveView.Socket.t()}
      def handle_params(_params, uri, socket) do
        # Manually set the :routex key as helpers_mod is not yet in the socket.
        attrs = unquote(helper_mod).attrs(uri)

        socket =
          Routex.Attrs.merge(socket, %{
            helpers_mod: unquote(helper_mod),
            url: uri,
            __branch__: attrs.__branch__
          })

        socket = Phoenix.Component.assign(socket, url: uri, __branch__: attrs.__branch__)
        {:cont, socket}
      end
    end
  end

  # Returns a quoted expression that attaches the Routex hook for `handle_params` to the socket.
  @spec build_routex_hook(module()) :: Macro.output()
  defp build_routex_hook(helper_mod) do
    quote do
      socket =
        Phoenix.LiveView.attach_hook(
          socket,
          unquote(__MODULE__),
          :handle_params,
          &unquote(helper_mod).handle_params/3
        )
    end
  end

  # Returns a quoted definition of `on_mount/4` which splices in provided hook AST blocks.
  @spec add_to_on_mount(Macro.output()) :: Macro.output()
  defp add_to_on_mount(hooks_ast) do
    quote do
      @spec on_mount(term(), map(), map(), Phoenix.LiveView.Socket.t()) ::
              {:cont, Phoenix.LiveView.Socket.t()}
      def on_mount(_key, _params, _session, socket) do
        unquote_splicing(hooks_ast)
        {:cont, socket}
      end
    end
  end

  # Builds case clauses for a given callback from per-backend extension callbacks.
  @spec build_cases(atom(), Macro.output(), map()) :: Macro.output()
  defp build_cases(callback, callback_vars, extensions_per_backend) do
    for {backend, extensions} <- extensions_per_backend, extensions != [] do
      clauses =
        for ext <- extensions do
          quote do
            {:cont, socket} <- unquote(ext).unquote(callback)(unquote_splicing(callback_vars))
          end
        end

      quote do
        unquote(backend) ->
          with unquote_splicing(clauses) do
            {:cont, socket}
          end
      end
    end
    |> List.flatten()
  end

  # Builds a callback function for the given lifecycle stage based on backend cases.
  @spec build_functions(Macro.output(), Macro.output(), module()) :: Macro.output() | nil
  defp build_functions(_hook_vars, [], _helper_mod), do: nil

  defp build_functions(hook_vars, cases, helper_mod) do
    quote do
      fn unquote_splicing(hook_vars) ->
        attrs = unquote(helper_mod).attrs(Routex.Attrs.get!(socket, :url))

        case attrs.__backend__ do
          [unquote_splicing(cases)]
        end
      end
    end
    |> Routex.Dev.print_ast()
  end

  # Returns a quoted expression that attaches a hook for the specified callback using the given function.
  @spec build_hook(atom(), Macro.output()) :: Macro.output()
  defp build_hook(callback, fun) do
    quote do
      socket =
        Phoenix.LiveView.attach_hook(
          socket,
          __MODULE__,
          unquote(callback),
          unquote(fun)
        )
    end
  end

  # Creates LiveView hooks for each supported lifecycle stage using the provided routes and helper module.
  @spec create_liveview_hooks(map(), keyword(), module()) :: [Macro.output()]
  defp create_liveview_hooks(routes_per_backend, livecycle_stages, helper_mod) do
    backends = Keyword.keys(routes_per_backend)

    Enum.reduce(livecycle_stages, [], fn {callback, args}, acc ->
      per_backend_result =
        for backend <- backends, backend != nil, into: %{} do
          extensions =
            backend.extensions()
            |> Enum.filter(&function_exported?(&1, callback, length(args) + 1))

          {backend, extensions}
        end

      hook_vars = Enum.map(args, &Macro.var(&1, __MODULE__))
      callback_vars = hook_vars ++ [Macro.var(:attrs, __MODULE__)]
      cases = build_cases(callback, callback_vars, per_backend_result)
      fun = build_functions(hook_vars, cases, helper_mod)

      hook = if fun, do: build_hook(callback, fun), else: []
      [hook | acc]
    end)
  end
end
