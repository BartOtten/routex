defmodule Routex.Utils do
  @moduledoc """
  Provides an interface to functions which can be used in extensions.
  """

  @doc """
  Prints an indented text. Should be used when printing messages in
  the terminal during compile time.
  """
  @spec print(input :: iodata) :: binary
  def print(input), do: IO.puts([">> " | input])

  @doc """
  Returns the AST to get the current branch from the process dictionary
  """
  @spec get_branch_from_process_ast(log_level :: atom) :: Macro.output()
  def get_branch_from_process_ast(log_level) do
    quote do
      require Logger

      case branch = Process.get(:rtx_branch, :not_found) do
        :not_found ->
          Logger.unquote(log_level)(
            "No helper AST and no proces key `:rtx_branch` found. Fallback to `0`"
          )

          0

        _ ->
          branch
      end
    end
  end

  @doc """
  Returns the AST to get the current branch from assigns, conn or socket based on the available
  variables in the __CALLER__ module.
  """
  @spec get_helper_ast(caller :: Macro.Env.t()) :: Macro.output()
  def get_helper_ast(caller) do
    vars =
      caller.versioned_vars
      |> Enum.filter(fn
        {{var, _}, _} when var in [:socket, :conn, :assigns] ->
          true

        _other ->
          false
      end)
      |> Enum.map(fn {{var, _}, _} -> var end)

    cond do
      :assigns in vars ->
        quote do
          case var!(assigns) do
            %{conn: %{private: %{routex: %{__branch__: order}}}} ->
              List.last(order)

            %{__branch__: order} ->
              List.last(order)
          end
        end

      :conn in vars ->
        quote do
          var!(conn).private.routex.__branch__ |> List.last()
        end

      :socket in vars ->
        quote do
          case var!(socket) do
            %{private: %{routex: %{__branch__: order}}} ->
              List.last(order)

            %{private: %{connect_info: %{private: %{routex: %{__branch__: order}}}}} ->
              List.last(order)

            _ ->
              require Logger

              Logger.warning("""
              Using branching verified routes in `mount/3` is not supported.
              Please move the code to the `handle_params/3`.
              """)

              {:current_stacktrace, st} = Process.info(self(), :current_stacktrace)
              st |> tl |> Exception.format_stacktrace() |> Logger.warning()

              0
          end
        end

      ExUnit.Callbacks in caller.requires ->
        get_branch_from_process_ast(:info)

      true ->
        get_branch_from_process_ast(:warning)
    end
  end
end
