defmodule Routex.Extension.PlugsTest do
  use ExUnit.Case

  # A dummy extension that exports plug/3
  defmodule DummyPlugExtension1 do
    @moduledoc false
    def plug(conn, opts, attrs) do
      # For testing, simply return a tuple indicating it was called.
      {:called, conn, opts, attrs}
    end
  end

  # A dummy extension that exports plug/3
  defmodule DummyPlugExtension2 do
    @moduledoc false
    def plug(conn, opts, attrs) do
      # For testing, simply return a tuple indicating it was called.
      {:called, conn, opts, attrs}
    end
  end

  # A dummy backend that returns a configuration with plugs.
  defmodule DummyBackend1 do
    @moduledoc false
    def config, do: %{plugs: [plug: [DummyPlugExtension1]]}
  end

  # A dummy backend that returns a configuration with plugs.
  defmodule DummyBackend2 do
    @moduledoc false
    def config, do: %{plugs: [plug: [DummyPlugExtension1, DummyPlugExtension2]]}
  end

  alias Routex.Extension.Plugs

  @routes [
    %Phoenix.Router.Route{private: %{routex: %{__backend__: DummyBackend1}}},
    %Phoenix.Router.Route{private: %{routex: %{__backend__: DummyBackend2}}}
  ]

  describe "configure/2" do
    test "registers valid plug callbacks" do
      opts = [extensions: [DummyPlugExtension1]]
      new_opts = Plugs.configure(opts, DummyBackend1)
      assert Keyword.has_key?(new_opts, :plugs)

      plugs = Keyword.get(new_opts, :plugs)
      # We expect that under the key :plug the DummyPlugExtension is accumulated.
      assert DummyPlugExtension1 in Keyword.get(plugs, :plug)
    end

    test "returns opts with empty :plugs when no extensions provided" do
      opts = []
      new_opts = Plugs.configure(opts, DummyBackend1)
      # :extensions defaults to [] so no plug callbacks are registered.
      assert Keyword.get(new_opts, :plugs) == []
    end
  end

  describe "create_helpers/3" do
    test "generates plug helper code" do
      helpers = Plugs.create_helpers(@routes, DummyBackend1, %{})

      # The helpers function returns a list of quoted expressions.
      assert is_list(helpers)
      # In our dummy setup we have two backends so we expect two quoted expression.
      assert length(helpers) == 2

      helper_ast = List.first(helpers)
      helper_str = Macro.to_string(helper_ast)

      # The generated code should include the definition of the plug function.
      assert helper_str =~ "def plug("
      # It should reference the backend
      assert helper_str =~
               "%{private: %{routex: %{__backend__: Routex.Extension.PlugsTest.DummyBackend1}}} = conn"
    end
  end
end
