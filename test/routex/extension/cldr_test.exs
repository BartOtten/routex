defmodule Routex.Extension.CldrTest.MockBackend.Locale do
  def new(locale = "en"),
    do: {:ok, %{cldr_locale_name: locale, language: locale, territory: "US"}}

  def new(locale = "fr"),
    do: {:ok, %{cldr_locale_name: locale, language: locale, territory: "FR"}}

  def new(locale = "es"),
    do: {:ok, %{cldr_locale_name: locale, language: locale, territory: "ES"}}

  def territory_from_locale(locale_map), do: locale_map.territory
end

defmodule Routex.Extension.CldrTest.MockBackend.LocaleDisplay do
  def display_name("en", _), do: {:ok, "English"}
  def display_name("fr", _), do: {:ok, "French"}
  def display_name("es", _), do: {:ok, "Spanish"}
end

defmodule Routex.Extension.CldrTest do
  use ExUnit.Case

  alias Routex.Extension.Cldr

  defmodule MockBackend do
    def default_locale, do: "en"

    def known_locale_names, do: ["en", "fr", "es"]

    def known_gettext_locale_names, do: ["en", "fr", "es"]
  end

  test "configure/2 sets the correct alternatives" do
    config = [cldr_backend: MockBackend]

    expected_alternatives = %{
      "/" => %{
        attrs: %{
          language: "en",
          territory: "US",
          locale: "en",
          locale_name: "English"
        },
        branches: %{
          "/en" => %{
            attrs: %{language: "en", territory: "US", locale: "en", locale_name: "English"}
          },
          "/fr" => %{
            attrs: %{language: "fr", territory: "FR", locale: "fr", locale_name: "French"}
          },
          "/es" => %{
            attrs: %{language: "es", territory: "ES", locale: "es", locale_name: "Spanish"}
          }
        }
      }
    }

    new_config = Cldr.configure(config, nil)

    assert Keyword.get(new_config, :alternatives) == expected_alternatives
  end
end
