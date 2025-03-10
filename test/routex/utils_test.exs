defmodule Routex.UtilsTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO
  import ExUnit.CaptureLog

  alias Routex.Utils

  describe "print/1" do
    test "returns :noop input is nil" do
      assert Utils.print(nil) == :noop
    end

    test "prints a message without module prefix" do
      output =
        capture_io(fn ->
          Utils.print("no module")
        end)

      assert output =~ ">> no module"
    end

    test "sanitizes atom input" do
      output =
        capture_io(fn ->
          Utils.print(:an_atom)
        end)

      assert output =~ ">> an_atom"
    end

    test "sanitizes list input by rejecting nils" do
      output =
        capture_io(fn ->
          Utils.print(["line1", nil, "line2"])
        end)

      # The nil is removed so we should see the two lines concatenated.
      assert output =~ ">> line1line2\e[0m\n"
    end
  end

  describe "print/2" do
    test "returns :noop when both module and input are nil" do
      assert Utils.print(nil, nil) == :noop
    end

    test "prints a message with module prefix when module is provided" do
      output =
        capture_io(fn ->
          Utils.print(__MODULE__, "test message")
        end)

      # The printed output should include the inspected module and the message.
      assert output =~ inspect(__MODULE__)
      assert output =~ ">> test message"
    end

    test "prints a message without module prefix when module is nil" do
      output =
        capture_io(fn ->
          Utils.print(nil, "no module")
        end)

      assert output =~ ">> no module"
    end

    test "sanitizes atom input" do
      output =
        capture_io(fn ->
          Utils.print(nil, :an_atom)
        end)

      assert output =~ ">> an_atom"
    end

    test "sanitizes list input by rejecting nils" do
      output =
        capture_io(fn ->
          Utils.print(nil, ["line1", nil, "line2"])
        end)

      # The nil is removed so we should see the two lines concatenated.
      assert output =~ ">> line1line2\e[0m\n"
    end
  end

  describe "alert/1" do
    test "prints an alert with default title" do
      output =
        capture_io(fn ->
          Utils.alert("Something went wrong")
        end)

      assert output =~ "Critical"
      assert output =~ "Something went wrong"
    end
  end

  describe "alert/2" do
    test "prints an alert with the given title and input" do
      output =
        capture_io(fn ->
          Utils.alert("ALERT", "Something went wrong")
        end)

      assert output =~ "ALERT"
      assert output =~ "Something went wrong"
    end

    test "uses default title when title is not explicitly provided" do
      # Since the title has a default value, we provide two arguments.
      output =
        capture_io(fn ->
          Utils.alert("Critical", "Default title test")
        end)

      assert output =~ "Critical"
      assert output =~ "Default title test"
    end
  end

  describe "get_branch/1" do
    test "returns the last element of branch from a valid map" do
      input = %{private: %{routex: %{__branch__: [1, 2, 3]}}}
      assert Utils.get_branch(input) == 3
    end

    test "logs a warning and returns 0 when input is not a valid branch map" do
      log =
        capture_log(fn ->
          assert Utils.get_branch(%{}) == 0
        end)

      assert log =~ "Using branching verified routes in `mount/3` is not supported"
    end
  end

  describe "get_helper_ast/1" do
    test "returns AST that yields the branch from the process dictionary when set" do
      # Set the process dictionary key
      Process.put(:rtx_branch, 42)

      # Passing a dummy caller (with empty vars and requires) is enough since the process dict takes precedence.
      caller = %{
        module: __MODULE__,
        versioned_vars: [],
        requires: []
      }

      ast = Utils.get_helper_ast(caller)
      {result, _bindings} = Code.eval_quoted(ast)
      assert result == 42

      Process.delete(:rtx_branch)
    end

    test "returns AST that uses assigns when available" do
      # Simulate a caller with :assigns available
      caller = %{
        module: __MODULE__,
        versioned_vars: [{{:assigns, nil}, nil}],
        requires: []
      }

      # The AST assigns 'assigns' from the caller.
      # We simulate an assigns variable with a :conn that carries a branch.
      assigns = %{conn: %{private: %{routex: %{__branch__: [100]}}}}

      ast = Utils.get_helper_ast(caller)
      {result, _bindings} = Code.eval_quoted(ast, assigns: assigns)
      assert result == 100
    end

    test "returns AST that uses conn when available" do
      # Simulate a caller with :conn available
      caller = %{
        module: __MODULE__,
        versioned_vars: [{{:conn, nil}, nil}],
        requires: []
      }

      conn = %{private: %{routex: %{__branch__: [200]}}}
      ast = Utils.get_helper_ast(caller)
      {result, _bindings} = Code.eval_quoted(ast, conn: conn)
      assert result == 200
    end

    test "returns AST that uses socket when available" do
      # Simulate a caller with :socket available
      caller = %{
        module: __MODULE__,
        versioned_vars: [{{:socket, nil}, nil}],
        requires: []
      }

      socket = %{private: %{routex: %{__branch__: [300]}}}
      ast = Utils.get_helper_ast(caller)
      {result, _bindings} = Code.eval_quoted(ast, socket: socket)
      assert result == 300
    end

    test "returns 0 when ExUnit.Callbacks is in caller.requires" do
      caller = %{
        module: __MODULE__,
        versioned_vars: [],
        requires: [ExUnit.Callbacks]
      }

      ast = Utils.get_helper_ast(caller)
      {result, _bindings} = Code.eval_quoted(ast)
      assert result == 0
    end

    test "returns 0 and logs a warning when no available vars and no process dict key" do
      caller = %{
        module: __MODULE__,
        versioned_vars: [],
        requires: []
      }

      log =
        capture_log(fn ->
          ast = Utils.get_helper_ast(caller)
          {result, _bindings} = Code.eval_quoted(ast)
          assert result == 0
        end)

      assert log =~ "No helper AST and no proces key `:rtx_branch` found. Fallback to `0`"
    end
  end

  describe "ensure_compiled!/1" do
    test "returns the module if it is compiled" do
      # This test relies on Code.ensure_compiled!/1 behavior.
      assert Utils.ensure_compiled!(Utils) == Utils
    end

    # Optionally, you could test the error scenario if you had a dummy module known not to be compiled.
    # However, care must be taken because triggering compilation errors in tests might not be desirable.
  end
end
