defmodule Router.Attrs do
  @moduledoc false
  defstruct [:contact, locale: "en"]
end

defmodule MyAppWeb.RoutexBackend do
  @moduledoc false
  alias Router.Attrs

  use Routex.Backend,
    alternatives: %{
      "/" => %{
        attrs: %Attrs{contact: "root@example.com"},
        scopes: %{
          "/europe" => %{
            attrs: %Attrs{
              contact: "europe@example.com"
            },
            scopes: %{
              "/nl" => %{
                attrs: %Attrs{
                  locale: "nl",
                  contact: "verkoop@example.nl"
                }
              },
              "/be" => %{
                attrs: %Attrs{
                  locale: "nl",
                  contact: "handel@example.be"
                }
              }
            }
          },
          "/gb" => %{
            attrs: %Attrs{
              contact: "sales@example.com"
            }
          }
        }
      }
    },
    extensions: [
      Routex.Extension.Alternatives,
      Routex.Extension.AttrGetters
    ]
end

defmodule MyAppWeb.MultiLangRoutes do
  @moduledoc false
  alias Router.Attrs

  use(
    Routex,
    alternatives: %{
      "/" => %{
        attrs: %Attrs{contact: "root@example.com"},
        scopes: %{
          "/europe" => %{
            attrs: %Attrs{contact: "europe@example.com"},
            scopes: %{
              "/nl" => %{
                attrs: %Attrs{locale: "nl", contact: "verkoop@example.nl"}
              },
              "/be" => %{
                attrs: %Attrs{locale: "nl", contact: "handel@example.be"}
              }
            }
          },
          "/gb" => %{attrs: %Attrs{contact: "sales@example.com"}}
        }
      }
    },
    translations_backend: MyAppWeb.Gettext,
    assigns: %{namespace: :rtx, attrs: [:scope_helper, :locale, :contact, :name]},
    extensions: [
      Routex.Extension.Alternatives,
      Routex.Extension.Translations,
      Routex.Extension.AlternativeGetters,
      Routex.Extension.RouteHelpers,
      Routex.Extension.AttrGetters,
      Routex.Extension.Assigns
    ]
  )
end
