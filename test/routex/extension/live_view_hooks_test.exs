defmodule Routex.Extension.LiveViewHooksTest do
  use ExUnit.Case

  # A dummy extension that exports hook/3
  defmodule DummyHookExtension1 do
    @moduledoc false
    def handle_params(params, uri, socket, attrs) do
      # For testing, simply return a tuple indicating it was called.
      {:called, params, uri, socket, attrs}
    end
  end

  # A dummy extension that exports hook/3
  defmodule DummyHookExtension2 do
    @moduledoc false
    def handle_params(params, uri, socket, attrs) do
      # For testing, simply return a tuple indicating it was called.
      {:called, params, uri, socket, attrs}
    end
  end

  # A dummy backend that returns a configuration with hooks.
  defmodule DummyBackend1 do
    @moduledoc false
    def config, do: %{hooks: [handle_params: [DummyHookExtension1]]}
  end

  # A dummy backend that returns a configuration with hooks.
  defmodule DummyBackend2 do
    @moduledoc false
    def config, do: %{hooks: [handle_params: [DummyHookExtension1, DummyHookExtension2]]}
  end

  alias Routex.Extension.LiveViewHooks, as: Hooks

  @routes [
    %Phoenix.Router.Route{private: %{routex: %{__backend__: DummyBackend1}}},
    %Phoenix.Router.Route{private: %{routex: %{__backend__: DummyBackend2}}}
  ]

  describe "configure/2" do
    test "registers valid hook callbacks" do
      opts = [extensions: [DummyHookExtension1]]
      new_opts = Hooks.configure(opts, DummyBackend1)
      assert Keyword.has_key?(new_opts, :hooks)

      hooks = Keyword.get(new_opts, :hooks)
      # We expect that under the key :hook the DummyHookExtension is accumulated.
      assert DummyHookExtension1 in Keyword.get(hooks, :handle_params)
    end

    test "returns opts with empty :hooks when no extensions provided" do
      opts = []
      new_opts = Hooks.configure(opts, DummyBackend1)
      # :extensions defaults to [] so no hook callbacks are registered.
      assert Keyword.get(new_opts, :hooks) == []
    end
  end

  describe "create_helpers/3" do
    test "generates hook helper code" do
      helpers = Hooks.create_helpers(@routes, DummyBackend1, %{})

      # The helpers function returns a list of quoted expressions.
      assert is_list(helpers)
      # on_mount, handle_params and reduce_socket
      assert length(helpers) == 3

      helper_ast = List.first(helpers)
      helper_str = Macro.to_string(helper_ast)

      # The generated code should include the definition of the hook function.
      assert helper_str =~ "def on_mount("
      # It should reference the backend
      assert helper_str =~ "Routex.Extension.LiveViewHooksTest.DummyBackend1 ->"
    end
  end
end
