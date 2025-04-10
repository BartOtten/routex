defmodule Routex.Extension.Localize.DetectTest do
  use ExUnit.Case, async: true
  alias Routex.Extension.Localize.Detect
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
      conn = %{conn | query_params: %{"language" => "spa", "region" => "MX"}}

      result = Detect.detect_locales(conn, [], attrs)

      assert result.language == "spa"
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

  describe "normalize_locale_value/2" do
    test "handles two-letter codes" do
      assert Detect.normalize_locale_value("en", :language) == "en"
      assert Detect.normalize_locale_value("US", :region) == "US"
    end

    test "handles three-letter codes" do
      assert Detect.normalize_locale_value("eng", :language) == "eng"
      assert Detect.normalize_locale_value("USA", :region) == "USA"
    end

    test "handles hyphenated format" do
      assert Detect.normalize_locale_value("en-US", :language) == "en"
      assert Detect.normalize_locale_value("en-US", :region) == "US"
    end

    test "handles underscore format" do
      assert Detect.normalize_locale_value("pt_BR", :language) == "pt"
      assert Detect.normalize_locale_value("pt_BR", :region) == "BR"
    end

    test "returns nil for invalid formats" do
      assert Detect.normalize_locale_value("invalid", :language) == nil
      assert Detect.normalize_locale_value("", :region) == nil
      assert Detect.normalize_locale_value(nil, :language) == nil
    end

    test "preserves full locale value when key is :locale" do
      assert Detect.normalize_locale_value("en-US", :locale) == "en-US"
      assert Detect.normalize_locale_value("pt_BR", :locale) == "pt_BR"
    end
  end
end
