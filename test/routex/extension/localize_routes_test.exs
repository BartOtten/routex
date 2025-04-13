defmodule Routex.Extension.Localize.Phoenix.RoutesTest do
  use ExUnit.Case

  defmodule DummyOpts do
    @moduledoc false
    def opts(),
      do: [
        extensions: [Dummy],
        locales: [
          {"en-001", %{contact: "english@example.com", language_display_name: "Global"}},
          "fr",
          {"nl-BE", %{contact: "dutch@example.com", language_display_name: "Custom"}}
        ],
        default_locale: "en",
        locale_backend: Routex.Test.Support.Gettext,
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
    @moduledoc false
    defstruct contact: "default@example.com"
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

  alias Routex.Extension.Localize.Phoenix.Routes, as: Localize

  describe "configure/2" do
    test "adds alternative generating extension" do
      result = Localize.configure(DummyOpts.opts(), DummyBackend)
      assert result[:extensions] == [Routex.Extension.Alternatives, Dummy]
    end

    test "locale_route_prefix with single tag" do
      kv = [
        locale: ["/en-001", "/fr", "/nl-be"],
        language: ["/fr", "/nl"],
        region: ["/001", "/be"],
        language_display_name: ["/dutch", "/french"],
        region_display_name: ["/belgium", "/world"]
      ]

      for {primary_prefix, expected_prefixes} <- kv do
        opts =
          DummyOpts.opts()
          |> Keyword.put(:locale_prefix_sources, primary_prefix)

        result = Localize.configure(opts, DummyBackend)

        assert Map.keys(result[:alternatives]["/"][:branches]) == expected_prefixes
      end
    end

    test "locale_route_prefix with multi tags (fallback mechanism)" do
      kv = [
        locale: ["/en-001", "/fr", "/nl-be"],
        language: ["/fr", "/nl"],
        region: ["/001", "/be", "/fr"]
      ]

      for {primary_prefix, expected_prefixes} <- kv do
        other_prefixes = kv |> Keyword.keys() |> Keyword.delete(primary_prefix)

        opts =
          DummyOpts.opts()
          |> Keyword.put(:locale_prefix_sources, [primary_prefix | other_prefixes])

        result = Localize.configure(opts, DummyBackend)

        assert Map.keys(result[:alternatives]["/"][:branches]) == expected_prefixes
      end
    end

    test "locale_route_prefix with dual tags (fallback mechanism)" do
      base_opts =
        DummyOpts.opts()
        |> Keyword.put(:default_locale, "en")

      primary_prefix = [:region]
      other_prefixes = [:language]
      opts = Keyword.put(base_opts, :locale_prefix_sources, [primary_prefix | other_prefixes])

      result = Localize.configure(opts, DummyBackend)
      expected = ["/001", "/be", "/fr"]

      assert Map.keys(result[:alternatives]["/"][:branches]) == expected

      # and the other way around
      primary_prefix2 = [:language]
      other_prefixes2 = [:region]
      opts2 = Keyword.put(base_opts, :locale_prefix_sources, [primary_prefix2 | other_prefixes2])

      result2 = Localize.configure(opts2, DummyBackend)
      expected2 = ["/fr", "/nl"]

      assert Map.keys(result2[:alternatives]["/"][:branches]) == expected2
    end

    test "creates alternatives when none available" do
      result = Localize.configure(DummyOpts.opts(), DummyBackend)

      expected_alts =
        %{
          "/" => %{
            attrs: %{
              contact: "english@example.com",
              language: "en",
              language_display_name: "Global",
              locale: "en-001",
              region: "001",
              region_display_name: "World",
              prefix: "/"
            },
            branches: %{
              "/fr" => %{
                attrs: %{
                  language: "fr",
                  language_display_name: "French",
                  locale: "fr",
                  region: nil,
                  region_display_name: nil,
                  prefix: "/fr"
                }
              },
              "/nl" => %{
                attrs: %{
                  contact: "dutch@example.com",
                  language: "nl",
                  language_display_name: "Custom",
                  locale: "nl-BE",
                  region: "BE",
                  region_display_name: "Belgium",
                  prefix: "/nl"
                }
              }
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
      result = Localize.configure(opts, DummyBackend)

      expected_alts =
        %{
          "/" => %{
            attrs: %{
              contact: "root@example.com",
              language: "en",
              language_display_name: "Global",
              locale: "en-001",
              region: "001",
              region_display_name: "World",
              prefix: "/"
            },
            branches: %{
              "/foods" => %{
                attrs: %{
                  contact: "poison@example.com",
                  language: "en",
                  language_display_name: "Global",
                  locale: "en-001",
                  region: "001",
                  region_display_name: "World",
                  prefix: "/foods"
                }
              },
              "/fr" => %{
                attrs: %{
                  contact: "root@example.com",
                  language: "fr",
                  language_display_name: "French",
                  locale: "fr",
                  region: nil,
                  region_display_name: nil,
                  prefix: "/fr"
                },
                branches: %{
                  "/foods" => %{
                    attrs: %{
                      contact: "poison@example.com",
                      language: "fr",
                      language_display_name: "French",
                      locale: "fr",
                      region: nil,
                      region_display_name: nil,
                      prefix: "/foods"
                    }
                  },
                  "/sports" => %{
                    attrs: %{
                      contact: "sports@example.com",
                      language: "fr",
                      language_display_name: "French",
                      locale: "fr",
                      region: nil,
                      region_display_name: nil,
                      prefix: "/sports"
                    },
                    branches: %{
                      "/football" => %{
                        attrs: %{
                          contact: "footbal@example.com",
                          language: "fr",
                          language_display_name: "French",
                          locale: "fr",
                          region: nil,
                          region_display_name: nil,
                          prefix: "/football"
                        }
                      },
                      "/soccer" => %{
                        attrs: %{
                          contact: "soccer@example.com",
                          language: "fr",
                          language_display_name: "French",
                          locale: "fr",
                          region: nil,
                          region_display_name: nil,
                          prefix: "/soccer"
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
                  region_display_name: "Belgium",
                  prefix: "/nl"
                },
                branches: %{
                  "/foods" => %{
                    attrs: %{
                      contact: "poison@example.com",
                      language: "nl",
                      language_display_name: "Custom",
                      locale: "nl-BE",
                      region: "BE",
                      region_display_name: "Belgium",
                      prefix: "/foods"
                    }
                  },
                  "/sports" => %{
                    attrs: %{
                      contact: "sports@example.com",
                      language: "nl",
                      language_display_name: "Custom",
                      locale: "nl-BE",
                      region: "BE",
                      region_display_name: "Belgium",
                      prefix: "/sports"
                    },
                    branches: %{
                      "/football" => %{
                        attrs: %{
                          contact: "footbal@example.com",
                          language: "nl",
                          language_display_name: "Custom",
                          locale: "nl-BE",
                          region: "BE",
                          region_display_name: "Belgium",
                          prefix: "/football"
                        }
                      },
                      "/soccer" => %{
                        attrs: %{
                          contact: "soccer@example.com",
                          language: "nl",
                          language_display_name: "Custom",
                          locale: "nl-BE",
                          region: "BE",
                          region_display_name: "Belgium",
                          prefix: "/soccer"
                        }
                      }
                    }
                  }
                }
              },
              "/sports" => %{
                attrs: %{
                  contact: "sports@example.com",
                  language: "en",
                  language_display_name: "Global",
                  locale: "en-001",
                  region: "001",
                  region_display_name: "World",
                  prefix: "/sports"
                },
                branches: %{
                  "/football" => %{
                    attrs: %{
                      contact: "footbal@example.com",
                      language: "en",
                      language_display_name: "Global",
                      locale: "en-001",
                      region: "001",
                      region_display_name: "World",
                      prefix: "/football"
                    }
                  },
                  "/soccer" => %{
                    attrs: %{
                      contact: "soccer@example.com",
                      language: "en",
                      language_display_name: "Global",
                      locale: "en-001",
                      region: "001",
                      region_display_name: "World",
                      prefix: "/soccer"
                    }
                  }
                }
              }
            }
          },
          "/other_root" => %{
            attrs: %{
              contact: "other_root@example.com",
              language: "en",
              language_display_name: "Global",
              locale: "en-001",
              region: "001",
              region_display_name: "World",
              prefix: "/other_root"
            },
            branches: %{
              "/fr" => %{
                attrs: %{
                  contact: "other_root@example.com",
                  language: "fr",
                  language_display_name: "French",
                  locale: "fr",
                  region: nil,
                  region_display_name: nil,
                  prefix: "/fr"
                }
              },
              "/nl" => %{
                attrs: %{
                  contact: "other_root@example.com",
                  language: "nl",
                  language_display_name: "Custom",
                  locale: "nl-BE",
                  region: "BE",
                  region_display_name: "Belgium",
                  prefix: "/nl"
                }
              }
            }
          }
        }

      assert expected_alts == result[:alternatives]
    end
  end
end
