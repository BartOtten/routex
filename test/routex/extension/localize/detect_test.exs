defmodule Routex.Extension.Localize.Phoenix.DetectTest do
  use ExUnit.Case, async: true
  alias Routex.Extension.Localize.Phoenix.Detect
  alias Plug.Conn

  # Mock backend module for testing
  defmodule MockBackend do
    def config do
      %{
        region_sources: [:session, :query, :path],
        language_sources: [:session, :query, :path],
        locale_sources: [:session, :query, :path],
        region_params: ["region", "locale"],
        language_params: ["language", "locale"],
        locale_params: ["locale"]
      }
    end
  end

  setup do
    attrs = [__backend__: MockBackend]

    conn =
      %Conn{
        params: %{},
        path_params: %{},
        private: %{},
        assigns: %{}
      }
      |> Phoenix.ConnTest.init_test_session(%{token: "some-token"})

    {:ok, conn: conn, attrs: attrs}
  end

  describe "detect_locales/3" do
    test "detects locale from query parameters", %{conn: conn, attrs: attrs} do
      conn = %{conn | query_params: %{"locale" => "en-US"}}

      result = Detect.detect_locales(conn, [], attrs)

      assert result.language == "en"
      assert result.region == "US"
      assert result.territory == "US"
    end

    test "detects separate language and region from query parameters", %{conn: conn, attrs: attrs} do
      conn = %{conn | query_params: %{"language" => "fr", "region" => "CA"}}

      result = Detect.detect_locales(conn, [], attrs)

      assert result.language == "fr"
      assert result.region == "CA"
      assert result.territory == "CA"
    end

    test "handles underscore format in locale", %{conn: conn, attrs: attrs} do
      conn = %{conn | query_params: %{"locale" => "pt_BR"}}

      result = Detect.detect_locales(conn, [], attrs)

      assert result.language == "pt"
      assert result.region == "BR"
      assert result.territory == "BR"
    end

    test "handles three-letter language codes", %{conn: conn, attrs: attrs} do
      conn = %{conn | query_params: %{"language" => "ssp", "region" => "MX"}}

      result = Detect.detect_locales(conn, [], attrs)

      assert result.language == "ssp"
      assert result.region == "MX"
      assert result.territory == "MX"
    end

    test "returns nil for invalid format", %{conn: conn, attrs: attrs} do
      conn = %{conn | query_params: %{"locale" => "invalid"}}

      result = Detect.detect_locales(conn, [], attrs)

      assert result.language == nil
      assert result.region == nil
      assert result.territory == nil
    end

    test "returns nil for invalid language", %{conn: conn, attrs: attrs} do
      conn = %{conn | query_params: %{"language" => "foo"}}

      result = Detect.detect_locales(conn, [], attrs)

      assert result.language == nil
      assert result.region == nil
      assert result.territory == nil
    end

    test "handles path parameters", %{conn: conn, attrs: attrs} do
      conn = %{conn | path_params: %{"locale" => "de-AT"}}

      result = Detect.detect_locales(conn, [], attrs)

      assert result.language == "de"
      assert result.region == "AT"
      assert result.territory == "AT"
    end

    test "prioritizes sources order", %{conn: conn, attrs: attrs} do
      conn = %{conn | query_params: %{"locale" => "fr-FR"}, path_params: %{"locale" => "de-DE"}}

      result = Detect.detect_locales(conn, [], attrs)

      assert result.language == "fr"
      assert result.region == "FR"
      assert result.territory == "FR"
    end
  end
end
