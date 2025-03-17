defmodule Routex.Extension.SimpleLocaleTest do
  use ExUnit.Case

  # Define dummy modules for Gettext, Fluent, and Cldr so that they appear in the AST.
  defmodule Gettext do
    def put_locale(backend \\ nil, arg1), do: {:gettext, arg1, backend}
  end

  defmodule Fluent do
    def put_locale(backend \\ nil, arg1), do: {:fluent, arg1, backend}
  end

  defmodule Cldr do
    def put_locale(backend \\ nil, arg1), do: {:cldr, arg1, backend}
  end

  # Dummy helper module that records calls by sending messages.
  defmodule DummyHelper do
    def put_locale(attrs) do
      send(self(), {:put_locale_called, attrs})
      :ok
    end
  end

  # A dummy connection struct for testing plug/3.
  defmodule DummyConn do
    defstruct assigns: %{}, request_path: "/path", query_string: ""
  end

  defmodule DummyBackend do
    defstruct [:locale_backends, :translation_backends]
  end

  # Dummy backend returning a config struct (or map) with the required keys.
  defmodule DummyBackendGettext do
    def config,
      do: %DummyBackend{locale_backends: [{Cldr, Foo}], translation_backends: [{Gettext, Foo}]}
  end

  # Dummy backend returning a config struct (or map) with the required keys.
  defmodule DummyBackendFluent do
    def config,
      do: %DummyBackend{locale_backends: [{Cldr, Foo}], translation_backends: [{Fluent, Foo}]}
  end

  alias Routex.Extension.SimpleLocale

  describe "handle_params/4" do
    test "invokes the helper module and returns {:cont, socket}" do
      socket = %{dummy: true}
      attrs = %{__helper_mod__: DummyHelper, language: "en"}
      {:cont, returned_socket} = SimpleLocale.handle_params(%{}, "/some_url", socket, attrs)
      assert returned_socket == socket

      # Verify that DummyHelper.put_locale/1 was called with the given attrs.
      assert_received {:put_locale_called, ^attrs}
    end
  end

  describe "plug/3" do
    test "invokes the helper module and returns the same connection" do
      conn = %DummyConn{}
      attrs = %{__helper_mod__: DummyHelper, locale: "fr"}
      result_conn = SimpleLocale.plug(conn, [], attrs)
      assert result_conn == conn

      # Verify that DummyHelper.put_locale/1 was called.
      assert_received {:put_locale_called, ^attrs}
    end
  end

  describe "create_helpers/3 with Gettext" do
    test "generates AST that includes calls to the expected modules with config values" do
      ast = SimpleLocale.create_helpers([], DummyBackendGettext, %{module: __MODULE__})
      ast_str = Macro.to_string(ast)

      assert ast_str =~ "Gettext.put_locale"
      assert ast_str =~ "Cldr.put_locale"
      refute ast_str =~ "Fluent.put_locale"
    end
  end

  describe "create_helpers/3 with Fluent" do
    test "generates AST that includes calls to the expected modules with config values" do
      ast = SimpleLocale.create_helpers([], DummyBackendFluent, %{module: __MODULE__})
      ast_str = Macro.to_string(ast)

      assert ast_str =~ "Fluent.put_locale"
      assert ast_str =~ "Cldr.put_locale"
      refute ast_str =~ "Gettext.put_locale"
    end
  end
end
