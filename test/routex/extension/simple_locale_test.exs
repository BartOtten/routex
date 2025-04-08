defmodule Routex.Extension.SimpleLocaleTest do
  use ExUnit.Case

  defmodule DummyOpts do
    def opts(),
      do: [
        extensions: [Dummy],
        locales: [
          {"en-001", %{contact: "english@example.com", language_display_name: "Global"}},
          "fr",
          {"nl-BE", %{contact: "dutch@example.com", language_display_name: "Custom"}}
        ],
        default_locale: "en",
        locale_route_prefix: :language,
        region_sources: [:accept_language, :attrs],
        region_params: ["locale"],
        language_sources: [:query, :attrs],
        language_params: ["locale"],
        locale_sources: [:query, :session, :accept_language, :attrs],
        locale_params: ["locale"]
      ]
  end

  defmodule DummyAttrs do
    defstruct contact: "default@example.com"
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
    defstruct Keyword.keys(DummyOpts.opts())

    def config do
      struct(DummyBackend, DummyOpts.opts())
    end
  end

  alias Routex.Extension.SimpleLocale

  describe "configure/2" do
    test "adds alternative generating extension" do
      result = SimpleLocale.configure(DummyOpts.opts(), DummyBackend)
      assert result[:extensions] == [Routex.Extension.Alternatives, Dummy]
    end

    test "locale_route_prefix with single tag" do
      kv = [
        locale: ["/en-001", "/fr", "/nl-BE"],
        language: ["/fr", "/nl"],
        region: ["/001", "/BE"]
      ]

      for {primary_prefix, expected_prefixes} <- kv do
        opts =
          DummyOpts.opts()
          |> Keyword.put(:locale_branch_sources, primary_prefix)

        result = SimpleLocale.configure(opts, DummyBackend)

        assert Map.keys(result[:alternatives]["/"][:branches]) == expected_prefixes
      end
    end

    test "locale_route_prefix with multi tags (fallback mechanism)" do
      kv = [
        locale: ["/en-001", "/fr", "/nl-BE"],
        language: ["/fr", "/nl"],
        region: ["/001", "/BE", "/fr"]
      ]

      for {primary_prefix, expected_prefixes} <- kv do
        other_prefixes = kv |> Keyword.keys() |> Keyword.delete(primary_prefix)

        opts =
          DummyOpts.opts()
          |> Keyword.put(:locale_branch_sources, [primary_prefix | other_prefixes])

        result = SimpleLocale.configure(opts, DummyBackend)

        assert Map.keys(result[:alternatives]["/"][:branches]) == expected_prefixes
      end
    end

    test "locale_route_prefix with dual tags (fallback mechanism)" do
      base_opts =
        DummyOpts.opts()
        |> Keyword.put(:default_locale, "en")

      primary_prefix = [:region]
      other_prefixes = [:language]
      opts = Keyword.put(base_opts, :locale_branch_sources, [primary_prefix | other_prefixes])

      result = SimpleLocale.configure(opts, DummyBackend)
      expected = ["/001", "/BE", "/fr"]

      assert Map.keys(result[:alternatives]["/"][:branches]) == expected

      # and the other way around
      primary_prefix2 = [:language]
      other_prefixes2 = [:region]
      opts2 = Keyword.put(base_opts, :locale_branch_sources, [primary_prefix2 | other_prefixes2])

      result2 = SimpleLocale.configure(opts2, DummyBackend)
      expected2 = ["/fr", "/nl"]

      assert Map.keys(result2[:alternatives]["/"][:branches]) == expected2
    end

    test "creates alternatives when none available" do
      result = SimpleLocale.configure(DummyOpts.opts(), DummyBackend)

      expected_alts =
        %{
          "/" => %{
            branches: %{
              "/fr" => %{
                attrs: %{
                  locale: "fr",
                  language: "fr",
                  region: nil,
                  language_display_name: "French",
                  region_display_name: nil
                }
              },
              "/nl" => %{
                attrs: %{
                  language: "nl",
                  language_display_name: "Custom",
                  contact: "dutch@example.com",
                  locale: "nl-BE",
                  region: "BE",
                  region_display_name: "Belgium"
                }
              }
            },
            attrs: %{
              locale: "en-001",
              language: "en",
              region: "001",
              region_display_name: "World",
              contact: "english@example.com",
              language_display_name: "Global"
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
        },
        "/other_root" => %{attrs: %{contact: "other_root@example.com"}}
      }

      opts = [alternatives: pre_alts] ++ DummyOpts.opts()
      result = SimpleLocale.configure(opts, DummyBackend)

      expected_alts =
        %{
          "/" => %{
            attrs: %{
              contact: "root@example.com",
              language: "en",
              language_display_name: "Global",
              locale: "en-001",
              region: "001",
              region_display_name: "World"
            },
            branches: %{
              "/fr" => %{
                attrs: %{
                  language: "fr",
                  language_display_name: "French",
                  locale: "fr",
                  region: nil,
                  region_display_name: nil,
                  contact: "root@example.com"
                },
                branches: %{
                  "/foods" => %{
                    attrs: %{
                      contact: "poison@example.com",
                      language: "fr",
                      language_display_name: "French",
                      locale: "fr",
                      region: nil,
                      region_display_name: nil
                    }
                  },
                  "/sports" => %{
                    attrs: %{
                      contact: "sports@example.com",
                      language: "fr",
                      language_display_name: "French",
                      locale: "fr",
                      region: nil,
                      region_display_name: nil
                    },
                    branches: %{
                      "/football" => %{
                        attrs: %{
                          contact: "footbal@example.com",
                          language: "fr",
                          language_display_name: "French",
                          locale: "fr",
                          region: nil,
                          region_display_name: nil
                        }
                      },
                      "/soccer" => %{
                        attrs: %{
                          contact: "soccer@example.com",
                          language: "fr",
                          language_display_name: "French",
                          locale: "fr",
                          region: nil,
                          region_display_name: nil
                        }
                      }
                    }
                  }
                }
              },
              "/nl" => %{
                attrs: %{
                  contact: "root@example.com",
                  language: "nl",
                  language_display_name: "Custom",
                  locale: "nl-BE",
                  region: "BE",
                  region_display_name: "Belgium"
                },
                branches: %{
                  "/foods" => %{
                    attrs: %{
                      contact: "poison@example.com",
                      language: "nl",
                      language_display_name: "Custom",
                      locale: "nl-BE",
                      region: "BE",
                      region_display_name: "Belgium"
                    }
                  },
                  "/sports" => %{
                    attrs: %{
                      contact: "sports@example.com",
                      language: "nl",
                      language_display_name: "Custom",
                      locale: "nl-BE",
                      region: "BE",
                      region_display_name: "Belgium"
                    },
                    branches: %{
                      "/football" => %{
                        attrs: %{
                          contact: "footbal@example.com",
                          language: "nl",
                          language_display_name: "Custom",
                          locale: "nl-BE",
                          region: "BE",
                          region_display_name: "Belgium"
                        }
                      },
                      "/soccer" => %{
                        attrs: %{
                          contact: "soccer@example.com",
                          language: "nl",
                          language_display_name: "Custom",
                          locale: "nl-BE",
                          region: "BE",
                          region_display_name: "Belgium"
                        }
                      }
                    }
                  }
                }
              },
              "/foods" => %{
                attrs: %{
                  locale: "en-001",
                  region: "001",
                  region_display_name: "World",
                  language: "en",
                  language_display_name: "Global",
                  contact: "poison@example.com"
                }
              },
              "/sports" => %{
                attrs: %{
                  locale: "en-001",
                  region: "001",
                  region_display_name: "World",
                  language: "en",
                  language_display_name: "Global",
                  contact: "sports@example.com"
                },
                branches: %{
                  "/football" => %{
                    attrs: %{
                      locale: "en-001",
                      region: "001",
                      region_display_name: "World",
                      language: "en",
                      language_display_name: "Global",
                      contact: "footbal@example.com"
                    }
                  },
                  "/soccer" => %{
                    attrs: %{
                      locale: "en-001",
                      region: "001",
                      region_display_name: "World",
                      language: "en",
                      language_display_name: "Global",
                      contact: "soccer@example.com"
                    }
                  }
                }
              }
            }
          },
          "/other_root" => %{
            attrs: %{
              contact: "other_root@example.com",
              locale: "en-001",
              region: "001",
              region_display_name: "World",
              language: "en",
              language_display_name: "Global"
            },
            branches: %{
              "/fr" => %{
                attrs: %{
                  language: "fr",
                  language_display_name: "French",
                  region: nil,
                  region_display_name: nil,
                  contact: "other_root@example.com",
                  locale: "fr"
                }
              },
              "/nl" => %{
                attrs: %{
                  contact: "other_root@example.com",
                  language: "nl",
                  language_display_name: "Custom",
                  locale: "nl-BE",
                  region: "BE",
                  region_display_name: "Belgium"
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
