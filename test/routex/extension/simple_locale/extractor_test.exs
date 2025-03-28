defmodule Routex.Extension.SimpleLocale.ExtractorTest do
  use ExUnit.Case, async: true
  alias Routex.Extension.SimpleLocale.Extractor
  alias Plug.Conn

  # Mock the Registry module for testing purposes
  defmodule MockRegistry do
    def region?("US"), do: true
    def region?("GB"), do: true
    def region?(_), do: false

    def language?("en"), do: true
    def language?("fr"), do: true
    def language?(_), do: false
  end

  Code.compiler_options(ignore_module_conflict: true)

  defmodule SimpleLocale.Registry do
    defdelegate region?(value), to: MockRegistry
    defdelegate language?(value), to: MockRegistry
  end

  setup do
    conn =
      %Conn{
        req_headers: [],
        cookies: %{},
        params: %{},
        query_params: %{},
        path_params: %{},
        private: %{},
        assigns: %{},
        body_params: %{}
      }
      |> Phoenix.ConnTest.init_test_session(%{routex: %{"locale" => "nl-BE"}})

    {:ok, conn: conn}
  end

  describe "extract_from_source/4 with Plug.Conn - accept_language" do
    test "extracts from accept-language header", %{conn: conn} do
      conn = %{conn | req_headers: [{"accept-language", "en-US,en;q=0.9,fr;q=0.8"}]}

      result = Extractor.extract_from_source(conn, :accept_language, "language", [])
      assert result == "en"
    end

    test "returns nil for invalid accept-language header", %{conn: conn} do
      conn = %{conn | req_headers: [{"accept-language", "invalid"}]}

      result = Extractor.extract_from_source(conn, :accept_language, "language", [])
      assert is_nil(result)
    end
  end

  describe "extract_from_source/4 with Plug.Conn - cookie" do
    test "extracts from cookies", %{conn: conn} do
      conn = %{conn | cookies: %{"locale" => "en-US"}}

      result = Extractor.extract_from_source(conn, :cookie, "locale", [])
      assert result == "en-US"
    end

    test "returns nil for missing cookie", %{conn: conn} do
      result = Extractor.extract_from_source(conn, :cookie, "locale", [])
      assert is_nil(result)
    end
  end

  describe "extract_from_source/4 with Plug.Conn - query" do
    test "extracts from query params", %{conn: conn} do
      conn = %{conn | query_params: %{"locale" => "en-US"}}

      result = Extractor.extract_from_source(conn, :query, "locale", [])
      assert result == "en-US"
    end

    test "handles unfetched query params", %{conn: conn} do
      conn = %{conn | query_params: %Plug.Conn.Unfetched{}}

      result = Extractor.extract_from_source(conn, :query, "locale", [])
      assert is_nil(result)
    end
  end

  describe "extract_from_source/4 with Plug.Conn - session" do
    test "extracts from session", %{conn: conn} do
      conn = conn |> Phoenix.ConnTest.init_test_session(%{routex: %{"locale" => "en-US"}})

      result = Extractor.extract_from_source(conn, :session, "locale", [])
      assert result == "en-US"
    end

    test "returns nil for missing session data", %{conn: conn} do
      result =
        conn
        |> Plug.Conn.put_session(:routex, nil)
        |> Extractor.extract_from_source(:session, "locale", [])

      assert is_nil(result)
    end
  end

  describe "extract_from_source/4 with Plug.Conn - path" do
    test "extracts from path params", %{conn: conn} do
      conn = %{conn | path_params: %{"locale" => "en-US"}}

      result = Extractor.extract_from_source(conn, :path, "locale", [])
      assert result == "en-US"
    end

    test "returns nil for missing path params", %{conn: conn} do
      result = Extractor.extract_from_source(conn, :path, "locale", [])
      assert is_nil(result)
    end
  end

  describe "extract_from_source/4 with Map input" do
    test "extracts from map query params" do
      source = %{query_params: %{"locale" => "en-US"}}

      result = Extractor.extract_from_source(source, :query, "locale", [])
      assert result == "en-US"
    end

    test "extracts from map session" do
      source = %{
        private: %{
          routex: %{
            session: %{"locale" => "en-US"}
          }
        }
      }

      result = Extractor.extract_from_source(source, :session, "locale", [])
      assert result == "en-US"
    end

    test "extracts from map cookies" do
      source = %{cookies: %{"locale" => "en-US"}}

      result = Extractor.extract_from_source(source, :cookie, "locale", [])
      assert result == "en-US"
    end
  end

  describe "extract_from_source/4 - host extraction" do
    test "extracts valid locale from host", %{conn: conn} do
      conn = %{conn | host: "en.example.com"}

      result = Extractor.extract_from_source(conn, :host, "locale", [])
      assert result == "en"
    end

    test "returns nil for invalid host locale", %{conn: conn} do
      conn = %{conn | host: "invalid.example.com"}

      result = Extractor.extract_from_source(conn, :host, "locale", [])
      assert is_nil(result)
    end
  end

  describe "extract_from_source/4 - body params" do
    test "extracts from body params", %{conn: conn} do
      conn = %{conn | body_params: %{"locale" => "en-US"}}

      result = Extractor.extract_from_source(conn, :body, "locale", %{})
      assert result == "en-US"
    end

    test "returns nil for missing body params", %{conn: conn} do
      result = Extractor.extract_from_source(conn, :body, "locale", %{})
      assert is_nil(result)
    end
  end

  describe "extract_from_source/4 - attrs" do
    test "extracts from attrs" do
      attrs = %{locale: "en-US"}

      result = Extractor.extract_from_source(%{}, :attrs, "locale", attrs)
      assert result == "en-US"
    end

    test "returns nil for missing attrs" do
      result = Extractor.extract_from_source(%{}, :attrs, "locale", %{})
      assert is_nil(result)
    end

    test "handles non-existent atom keys" do
      attrs = %{locale: "en-US"}

      assert_raise ArgumentError, fn ->
        Extractor.extract_from_source(%{}, :attrs, "nonexistent", attrs)
      end
    end
  end

  describe "validate_locale_value/1 (via find_first_valid_segment/1)" do
    test "validates region value" do
      source = %{host: "US.example.com"}
      assert Extractor.extract_from_source(source, :host, "locale", %{}) == "US"
    end

    test "validates language value" do
      source = %{host: "en.example.com"}
      assert Extractor.extract_from_source(source, :host, "locale", %{}) == "en"
    end

    test "returns nil for invalid value" do
      source = %{host: "invalid.example.com"}
      assert Extractor.extract_from_source(source, :host, "locale", %{}) == nil
    end
  end
end
