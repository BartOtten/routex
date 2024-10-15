defmodule Router.Attrs do
  @moduledoc false
  defstruct [:contact, language: "en"]
end

defmodule MyAppWeb.RoutexBackend do
  @moduledoc false
  alias Router.Attrs

  use Routex.Backend,
    alternatives: %{
      "/" => %{
        attrs: %Attrs{contact: "root@example.com"},
        branches: %{
          "/europe" => %{
            attrs: %Attrs{
              contact: "europe@example.com"
            },
            branches: %{
              "/nl" => %{
                attrs: %Attrs{
                  language: "nl",
                  contact: "verkoop@example.nl"
                }
              },
              "/be" => %{
                attrs: %Attrs{
                  language: "nl",
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
      # Routex.Extension.Alternatives,
      Routex.Extension.AttrGetters
    ]
end

defmodule MyAppWeb.MultiLangRoutes do
  @moduledoc false
  alias Router.Attrs

  use(
    Routex.Backend,
    alternatives: %{
      "/" => %{
        attrs: %Attrs{contact: "root@example.com"},
        branches: %{
          "/europe" => %{
            attrs: %Attrs{contact: "europe@example.com"},
            branches: %{
              "/nl" => %{
                attrs: %Attrs{language: "nl", contact: "verkoop@example.nl"}
              },
              "/be" => %{
                attrs: %Attrs{language: "nl", contact: "handel@example.be"}
              }
            }
          },
          "/gb" => %{attrs: %Attrs{contact: "sales@example.com"}}
        }
      }
    },
    translations_backend: MyAppWeb.Gettext,
    assigns: %{namespace: :rtx, attrs: [:branch_helper, :language, :contact, :name]},
    extensions: [
      # Routex.Extension.Alternatives,
      # Routex.Extension.Translations,
      # Routex.Extension.AlternativeGetters,
      # Routex.Extension.RouteHelpers,
      Routex.Extension.AttrGetters,
      Routex.Extension.Assigns
    ]
  )
end
