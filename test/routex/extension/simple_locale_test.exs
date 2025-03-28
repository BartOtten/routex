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
    def conn,
      do: %Plug.Conn{
        req_headers: [{"accept-language", ["en-US,en;q=0.8,fr;q=0.6"]}],
        assigns: %{},
        request_path: "/path",
        query_string: ""
      }
  end

  defmodule DummyBackend do
    defstruct [:locale_backends, :translation_backends]

    def config,
      do: %DummyBackend{}
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
      socket = %Phoenix.LiveView.Socket{private: %{routex: %{}}}

      attrs = %{
        __backend__: DummyBackend,
        __helper_mod__: DummyHelper,
        locale: "en-US",
        type: :socket
      }

      {:cont, returned_socket} = SimpleLocale.handle_params(%{}, "/some_url", socket, attrs)
      assert returned_socket.private == socket.private

      # Verify that DummyHelper.put_locale/1 was called with the given attrs.
      expansion = %{language: "en", region: "US", territory: "US"}
      expected = Map.merge(attrs, expansion)

      assert_received {:put_locale_called, ^expected}
    end
  end

  describe "plug/3" do
    test "invokes the helper module" do
      conn = DummyConn.conn() |> Phoenix.ConnTest.init_test_session(%{token: "some-token"})

      attrs = %{
        __backend__: DummyBackend,
        __helper_mod__: DummyHelper,
        locale: "en-US",
        type: :conn
      }

      expansion = %{language: "en", region: "US", territory: "US"}

      _conn = SimpleLocale.plug(conn, [], attrs)
      expected = Map.merge(attrs, expansion)

      # Verify that DummyHelper.put_locale/1 was called.
      assert_received {:put_locale_called, ^expected}
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

  describe "parse accept language" do
    test "with language only fallbacks" do
      value = "en-US,en;q=0.9,zh-CN;q=0.8,zh;q=0.7"

      expected = [
        %{language: "en", locale: "en-US", quality: 1.0, territory: "US", region: "US"},
        %{language: "en", locale: "en", quality: 0.9, territory: nil, region: nil},
        %{language: "zh", locale: "zh-CN", quality: 0.8, territory: "CN", region: "CN"},
        %{language: "zh", locale: "zh", quality: 0.7, territory: nil, region: nil}
      ]

      assert expected == SimpleLocale.Parser.parse_accept_language(value)

      value1 = "*"
      expected1 = []
      assert expected1 == SimpleLocale.Parser.parse_accept_language(value1)

      value2 = "en"
      expected2 = [%{language: "en", locale: "en", quality: 1.0, territory: nil, region: nil}]
      assert expected2 == SimpleLocale.Parser.parse_accept_language(value2)

      value3 = "en-US"

      expected3 = [
        %{language: "en", locale: "en-US", quality: 1.0, territory: "US", region: "US"}
      ]

      assert expected3 == SimpleLocale.Parser.parse_accept_language(value3)
    end
  end
end
