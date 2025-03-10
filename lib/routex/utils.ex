defmodule Routex.Utils do
  @moduledoc """
  Provides an interface to functions which can be used in extensions.
  """

  @doc """
  Prints an indented text. Should be used when printing messages in
  the terminal during compile time.
  """

  alias Routex.Types, as: T

  # credo:disable-for-lines:2
  @spec print(module(), input :: iodata) :: :ok
  def print(module \\ nil, input)
  def print(nil, nil), do: :noop

  def print(module, input) do
    prefix = (module && [inspect(module), " "]) || ""
    IO.write([prefix, ">> ", sanitize(input), IO.ANSI.reset(), "\n"])
  end

  defp sanitize(input) when is_atom(input), do: to_string(input)
  defp sanitize(input) when is_list(input), do: Enum.reject(input, &is_nil/1)
  defp sanitize(input) when is_binary(input), do: input

  @doc """
  Prints an alert. Should be used when printing critical alerts in
  the terminal during compile time.
  """
  # credo:disable-for-lines:11
  @spec alert(input :: iodata) :: :ok
  def alert(title \\ "Critical", input),
    do:
      IO.write([
        IO.ANSI.blink_slow(),
        IO.ANSI.light_red_background(),
        sanitize(title),
        IO.ANSI.reset(),
        " ",
        sanitize(input),
        "\n"
      ])

  @doc """
  Returns the AST to get the current branch from process dict or from  assigns, conn or socket
  based on the available variables in the `caller` module.
  """
  @spec get_helper_ast(caller :: T.env()) :: T.ast()
  def get_helper_ast(caller) do
    quote do
      if branch = Process.get(:rtx_branch) do
        branch
      else
        unquote(get_derived_ast(caller))
      end
    end
  end

  defp get_derived_ast(caller) do
    vars = list_available_module_vars(caller)

    cond do
      :assigns in vars ->
        quote do
          assigns = var!(assigns)
          Routex.Utils.get_branch(assigns[:conn] || assigns[:socket])
        end

      :conn in vars ->
        quote do
          conn |> var!() |> Routex.Utils.get_branch()
        end

      :socket in vars ->
        quote do
          socket |> var!() |> Routex.Utils.get_branch()
        end

      ExUnit.Callbacks in caller.requires ->
        0

      true ->
        require Logger

        Logger.warning(
          "#{caller.module}: No helper AST and no proces key `:rtx_branch` found. Fallback to `0`"
        )

        0
    end
  end

  @spec get_branch(T.route() | map | Plug.Conn.t() | Phoenix.Socket.t()) :: integer()
  def get_branch(%{private: %{routex: %{__branch__: branch}}}) do
    List.last(branch)
  end

  def get_branch(_assigns_conn_socket) do
    require Logger

    Logger.warning("""
    Using branching verified routes in `mount/3` is not supported.
    Please move the code to the `handle_params/3`.
    """)

    {:current_stacktrace, st} = Process.info(self(), :current_stacktrace)
    st |> tl |> Exception.format_stacktrace() |> Logger.warning()

    0
  end

  @doc """
  Test env aware variant of Module.get_attribute. Delegates to
  `Module.get_attributes/3` in non-test environments. In test environment it
  returns the result of `Module.get_attributes/3` or an empty list when the
  module is already compiled.
  """
  if Mix.env() == :test do
    def get_attribute(module, key, default \\ nil) do
      Module.get_attribute(module, key, default)
    rescue
      ArgumentError ->
        alert(
          "TEST MODE",
          "Used fallback for `get_attributes(#{module}, #{key})`, returning an empty list"
        )

        []
    end
  else
    defdelegate get_attribute(module, key, default \\ nil), to: Module
  end

  # credo:disable-for-next-line
  # TODO: remove when we depend on Elixir 1.12+
  @doc """
  Backward compatible version of `Code.ensure_compiled!/1`
  """
  @spec ensure_compiled!(module()) :: module()
  if function_exported?(Code, :ensure_compiled!, 1) do
    def ensure_compiled!(mod), do: Code.ensure_compiled!(mod)
  else
    def ensure_compiled!(mod) do
      case Code.ensure_compiled(mod) do
        {:module, ^mod} ->
          mod

        {:error, reason} ->
          raise ArgumentError,
                "could not load module #{inspect(mod)} due to reason #{inspect(reason)}"
      end
    end
  end

  defp list_available_module_vars(caller) do
    caller.versioned_vars
    |> Enum.filter(fn
      {{var, _}, _} when var in [:socket, :conn, :assigns] ->
        true

      _other ->
        false
    end)
    |> Enum.map(fn {{var, _}, _} -> var end)
  end
end
