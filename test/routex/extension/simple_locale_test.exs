defmodule Routex.Extension.SimpleLocaleTest do
  use ExUnit.Case

  @opts [
    extensions: [Dummy],
    locales: [
      "en",
      "fr",
      {"nl", %{contact: "dutch@example.com", language_display_name: "Custom"}}
    ],
    default_locale: "en",
    region_sources: [:accept_language, :attrs],
    region_params: ["locale"],
    language_sources: [:query, :attrs],
    language_params: ["locale"],
    locale_sources: [:query, :session, :accept_language, :attrs],
    locale_params: ["locale"]
  ]

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
    defstruct [
      :extensions,
      :region_sources,
      :region_params,
      :language_sources,
      :language_params,
      :locale_sources,
      :locale_params,
      :locales,
      :default_locale
    ]

    def config do
      %DummyBackend{
        extensions: [Dummy],
        locales: [
          "en",
          "fr",
          {"nl", %{contact: "dutch@example.com", language_display_name: "Custom"}}
        ],
        default_locale: "en",
        region_sources: [:accept_language, :attrs],
        region_params: ["locale"],
        language_sources: [:query, :attrs],
        language_params: ["locale"],
        locale_sources: [:query, :session, :accept_language, :attrs],
        locale_params: ["locale"]
      }
    end
  end

  alias Routex.Extension.SimpleLocale

  describe "configure/2" do
    test "adds alternative generating extension" do
      result = SimpleLocale.configure(@opts, DummyBackend)
      assert result[:extensions] == [Routex.Extension.Alternatives, Dummy]
    end

    test "creates alternatives when none available" do
      result = SimpleLocale.configure(@opts, DummyBackend)

      expected_alts =
        %{
          "/" => %{
            branches: %{
              "/fr" => %{
                attrs: %{
                  language: "fr",
                  region: nil,
                  language_display_name: "French",
                  region_display_name: nil
                }
              },
              "/nl" => %{
                attrs: %{
                  language: "nl",
                  region: nil,
                  language_display_name: "Custom",
                  region_display_name: nil,
                  contact: "dutch@example.com"
                }
              }
            },
            attrs: %{
              language: "en",
              region: nil,
              language_display_name: "English",
              region_display_name: nil
            }
          }
        }

      assert expected_alts == result[:alternatives]
    end

    test "branches existing alternatives" do
      pre_alts = %{
        "/" => %{
          attrs: %{contact: "root@example.com"},
          branches: %{
            "/sports" => %{
              attrs: %{contact: "sports@example.com"},
              branches: %{
                "/soccer" => %{attrs: %{contact: "soccer@example.com"}},
                "/football" => %{attrs: %{contact: "footbal@example.com"}}
              }
            },
            "/foods" => %{attrs: %{contact: "poison@example.com"}}
          }
        }
      }

      opts = [alternatives: pre_alts] ++ @opts
      result = SimpleLocale.configure(opts, DummyBackend)

      expected_alts =
        %{
          "/" => %{
            attrs: %{contact: "root@example.com"},
            branches: %{
              "/fr" => %{
                attrs: %{
                  language: "fr",
                  language_display_name: "French",
                  region: nil,
                  region_display_name: nil,
                  contact: "root@example.com"
                },
                branches: %{
                  "/foods" => %{attrs: %{contact: "poison@example.com"}},
                  "/sports" => %{
                    attrs: %{contact: "sports@example.com"},
                    branches: %{
                      "/football" => %{attrs: %{contact: "footbal@example.com"}},
                      "/soccer" => %{attrs: %{contact: "soccer@example.com"}}
                    }
                  }
                }
              },
              "/nl" => %{
                attrs: %{
                  language: "nl",
                  language_display_name: "Custom",
                  region: nil,
                  region_display_name: nil,
                  contact: "dutch@example.com"
                },
                branches: %{
                  "/foods" => %{attrs: %{contact: "poison@example.com"}},
                  "/sports" => %{
                    attrs: %{contact: "sports@example.com"},
                    branches: %{
                      "/football" => %{attrs: %{contact: "footbal@example.com"}},
                      "/soccer" => %{attrs: %{contact: "soccer@example.com"}}
                    }
                  }
                }
              }
            }
          }
        }

      assert expected_alts == result[:alternatives]
    end
  end

  describe "handle_params/4" do
    test "expands the runtime attributes and returns {:cont, socket}" do
      socket = %Phoenix.LiveView.Socket{private: %{routex: %{}}}
      attrs = %{__backend__: DummyBackend, locale: "en-US"}

      {:cont, returned_socket} = SimpleLocale.handle_params(%{}, "/some_url", socket, attrs)
      expected = %{language: "en", region: "US", territory: "US", locale: "en-US"}

      assert returned_socket.private.routex == expected
    end
  end

  describe "plug/3" do
    test "expands the runtime attributes and returns a conn" do
      conn = DummyConn.conn() |> Phoenix.ConnTest.init_test_session(%{token: "some-token"})
      attrs = %{__backend__: DummyBackend, locale: "en-US"}
      expected = %{language: "en", region: "US", territory: "US", locale: "en-US"}

      %Plug.Conn{} = returned_conn = SimpleLocale.plug(conn, [], attrs)
      assert returned_conn.private.routex == expected
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
