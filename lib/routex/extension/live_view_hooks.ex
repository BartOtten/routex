defmodule Routex.Extension.LiveViewHooks do
  @moduledoc """
  Attach LiveView hooks provided by Routex extensions.

  This extension generates quoted functions to inject into LiveView's
  lifecycle stages. The hooks are built from a set of supported lifecycle
  callbacks provided by extensions.

  The first given arguments given to these callbacks adhere to the official
  specifications. One additional argument, `attrs` is added with the
  `Routex.Attrs` of the current route.
  """

  @behaviour Routex.Extension

  alias Routex.Route
  alias Routex.Types, as: T

  @supported_lifecycle_stages [
    handle_params: [:params, :uri, :socket],
    handle_event: [:event, :params, :socket],
    handle_info: [:msg, :socket],
    handle_async: [:name, :async_fun_result, :socket]
  ]

  @doc """
  Detect supported lifecycle callbacks in extensions and adds
  them to `opts[:hooks]`.

  Detects and registers supported lifecycle callbacks from other extensions.
  Returns an updated keyword list with the valid callbacks accumulated
  under the `:hooks` key.

  **Supported callbacks:**
  #{inspect(@supported_lifecycle_stages)}
  """
  @impl Routex.Extension
  @spec configure(T.opts(), T.backend()) :: T.opts()
  def configure(opts, _backend) do
    opts = Keyword.put_new(opts, :hooks, [])
    extensions = Keyword.get(opts, :extensions, [])

    _opts =
      for extension <- extensions,
          {callback, params} <- @supported_lifecycle_stages,
          function_exported?(extension, callback, length(params) + 1),
          reduce: opts do
        acc ->
          update_in(acc, [:hooks, callback], &[extension | List.wrap(&1)])
      end
  end

  @doc """
  Generates Routex' LiveView `on_mount/4` hook, which inlines the lifecycle
  stage hooks provided by other extensions.

  Returns  on_mount/4` and an initial `handle_params/3`.
  """
  @impl Routex.Extension
  @spec create_helpers(T.routes(), T.backend(), T.env()) :: T.ast()
  def create_helpers(routes, _backend, _env) do
    backends = Route.get_backends(routes)

    rtx_hook = build_routex_hook()
    extension_hooks = create_liveview_hooks(backends, @supported_lifecycle_stages)

    on_mount_ast = build_on_mount_ast([rtx_hook | extension_hooks])
    handle_params_ast = build_handle_params()
    socket_reducer_ast = build_socket_reducer()

    [on_mount_ast, handle_params_ast, socket_reducer_ast]
  end

  defp build_socket_reducer do
    quote do
      defp reduce_socket(enumerable, acc, fun) do
        {result, flag} =
          Enum.reduce_while(enumerable, {acc, :cont}, fn elem, {acc, _flag} ->
            case fun.(elem, acc) do
              {:cont, new_acc} -> {:cont, {new_acc, :cont}}
              {:halt, new_acc} -> {:halt, {new_acc, :halt}}
            end
          end)

        {flag, result}
      end
    end
  end

  # Creates LiveView hooks for each supported lifecycle stage using the provided routes and helper module.
  @spec create_liveview_hooks(list(), keyword()) :: [] | [Macro.output()]
  defp create_liveview_hooks(backends, lifecycle_stages) do
    Enum.reduce(lifecycle_stages, [], fn {callback, args}, acc ->
      per_backend_result =
        for backend <- backends,
            config = backend.config(),
            hooks = Map.get(config, :hooks, []),
            extensions <- Keyword.get_values(hooks, callback),
            do: {backend, extensions}

      # credo:disable-for-lines:2
      hook_vars = Enum.map(args, &Macro.var(&1, __MODULE__))
      callback_vars = hook_vars ++ [Macro.var(:attrs, __MODULE__)]

      cases = build_cases(callback, callback_vars, per_backend_result)
      fun = build_functions(hook_vars, cases)

      hook = if fun, do: build_hook(callback, fun), else: nil

      if hook do
        [hook | acc]
      else
        acc
      end
    end)
  end

  # Builds case clauses for a given callback from per-backend extension callbacks.
  @spec build_cases(atom(), Macro.output(), keyword()) :: Macro.output()
  defp build_cases(callback, callback_vars, extensions_per_backend) do
    Enum.flat_map(extensions_per_backend, fn {backend, extensions} ->
      quote do
        unquote(backend) ->
          reduce_socket(unquote(extensions), socket, fn ext, socket ->
            ext.unquote(callback)(unquote_splicing(callback_vars))
          end)
      end
    end)
  end

  # Builds a callback function for the given lifecycle stage based on backend cases.
  @spec build_functions(Macro.output(), Macro.output()) :: Macro.output() | nil
  defp build_functions(_hook_vars, []), do: nil

  defp build_functions(hook_vars, cases) do
    quote do
      fn unquote_splicing(hook_vars) ->
        # not each callback has the uri param
        attrs = socket |> Routex.Attrs.get!(:url) |> attrs()

        case attrs.__backend__ do
          [unquote_splicing(cases)]
        end
      end
    end
  end

  # Returns a quoted definition for `handle_params/3` that assigns Routex attributes to the socket.
  @spec build_handle_params :: Macro.output()
  defp build_handle_params do
    {:ok, phx_version} = :application.get_key(:phoenix, :vsn)

    module =
      if phx_version |> to_string() |> Version.match?("< 1.7.0-dev") do
        Phoenix.LiveView
      else
        Phoenix.Component
      end

    quote do
      @spec handle_params(map(), binary(), Phoenix.LiveView.Socket.t()) ::
              {:cont, Phoenix.LiveView.Socket.t()}
      def handle_params(_params, uri, socket) do
        attrs = attrs(uri)

        merge_rtx_attrs = fn socket ->
          Routex.Attrs.merge(socket, %{
            helpers_mod: unquote(nil),
            url: uri,
            __branch__: attrs.__branch__
          })
        end

        socket =
          socket
          |> merge_rtx_attrs.()
          |> unquote(module).assign(url: uri, __branch__: attrs.__branch__)

        {:cont, socket}
      end
    end
  end

  # Returns a quoted expression that attaches the Routex hook for `handle_params` to the socket.
  @spec build_routex_hook :: Macro.output()
  defp build_routex_hook do
    quote do
      Phoenix.LiveView.attach_hook(__MODULE__, :handle_params, &handle_params/3)
    end
  end

  # Returns a quoted definition of `on_mount/4` which splices in provided hook AST blocks.
  @spec build_on_mount_ast(Macro.output()) :: Macro.output()
  defp build_on_mount_ast(hooks_ast) do
    piped_hooks =
      Enum.reduce(
        hooks_ast,
        quote do
          socket
        end,
        fn hook, acc ->
          quote do
            unquote(acc) |> unquote(hook)
          end
        end
      )

    quote do
      @spec on_mount(term(), map(), map(), Phoenix.LiveView.Socket.t()) ::
              {:cont, Phoenix.LiveView.Socket.t()} | {:halt, Phoenix.LiveView.Socket.t()}
      @doc "Implements the on_mount"
      def on_mount(_key, _params, _session, socket) do
        socket = unquote(piped_hooks)
        {:cont, socket}
      end
    end
  end

  # Returns a quoted expression that attaches a hook for the specified callback using the given function.
  @spec build_hook(atom(), Macro.output()) :: Macro.output()
  defp build_hook(callback, fun) do
    quote do
      Phoenix.LiveView.attach_hook(unquote(__MODULE__), unquote(callback), unquote(fun))
    end
  end
end
