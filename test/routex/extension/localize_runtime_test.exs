defmodule Routex.Extension.Localize.Phoenix.RuntimeTest do
  use ExUnit.Case
  alias Routex.Extension.Localize.Phoenix.Runtime

  defmodule DummyOpts do
    @moduledoc false
    def opts(),
      do: [
        extensions: [Dummy],
        default_locale: "en",
        region_sources: [:accept_language, :route],
        region_params: ["locale"],
        language_sources: [:query, :route],
        language_params: ["locale"],
        locale_sources: [:query, :session, :accept_language, :route],
        locale_params: ["locale"]
      ]
  end

  # A dummy connection struct for testing plug/3.
  defmodule DummyConn do
    @moduledoc false
    def conn,
      do: %Plug.Conn{
        req_headers: [{"accept-language", ["en-US,en;q=0.8,fr;q=0.6"]}],
        assigns: %{},
        request_path: "/path",
        query_string: ""
      }
  end

  defmodule DummyBackend do
    @moduledoc false
    defstruct Keyword.keys(DummyOpts.opts())

    def config do
      struct(DummyBackend, DummyOpts.opts())
    end
  end

  describe "handle_params/4" do
    test "expands the runtime attributes and returns {:cont, socket}" do
      attrs = %{__backend__: DummyBackend, locale: "en-US"}
      socket = %Phoenix.LiveView.Socket{private: %{routex: %{}}} |> Routex.Attrs.merge(attrs)

      {:cont, returned_socket} = Runtime.handle_params(%{}, "/some_url", socket)

      expected = %{
        __backend__: DummyBackend,
        locale: "en-US",
        runtime: %{language: "en", region: "US", territory: "US", locale: "en-US"}
      }

      assert returned_socket.private.routex == expected
    end

    test "works with list query params values with []" do
      attrs = %{__backend__: DummyBackend, locale: "en-US"}
      socket = %Phoenix.LiveView.Socket{private: %{routex: %{}}} |> Routex.Attrs.merge(attrs)

      {:cont, returned_socket} =
        Runtime.handle_params(%{}, "/some_url?items[]=1&items[]=2", socket)

      expected = %{
        __backend__: DummyBackend,
        locale: "en-US",
        runtime: %{language: "en", region: "US", territory: "US", locale: "en-US"}
      }

      assert returned_socket.private.routex == expected
    end
  end

  describe "plug/3" do
    test "expands the runtime attributes and returns a conn" do
      attrs = %{__backend__: DummyBackend, locale: "en-US"}

      conn =
        DummyConn.conn()
        |> Phoenix.ConnTest.init_test_session(%{token: "some-token"})
        |> Routex.Attrs.merge(attrs)

      expected = %{
        __backend__: DummyBackend,
        locale: "en-US",
        runtime: %{
          language: "en",
          region: "US",
          territory: "US",
          locale: "en-US"
        }
      }

      %Plug.Conn{} = returned_conn = Runtime.call(conn, [])
      assert returned_conn.private.routex == expected
    end
  end
end
