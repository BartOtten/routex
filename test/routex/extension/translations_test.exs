defmodule Routex.Extension.TranslationsTest do
  defmodule RtxBackend do
    use Routex.Backend,
      extensions: [Routex.Extension.Translations],
      translations_backend: Routex.Test.Support.Gettext
  end

  use ExUnit.Case

  alias Routex.Extension.Translations
  alias Phoenix.Router.Route

  @default_attrs %{__branch__: [0, 1], backend: RtxBackend, locale: "en-US"}
  defp route(rtx \\ @default_attrs), do: %Route{path: "/products/:id", private: %{routex: rtx}}

  test "should raise when no gettext backend is set" do
    exception =
      assert_raise RuntimeError, fn ->
        defmodule RtxErrorBackend do
          use(Routex.Backend, extensions: [Routex.Extension.Translations])
        end
      end

    assert exception.message ==
             "Expected `:translations_backend` to be set in Elixir.Routex.Extension.TranslationsTest.RtxErrorBackend"
  end

  test "should raise when neither :language or :locale attribute is set in a route" do
    failing_route = Map.delete(@default_attrs, :locale) |> route()

    routes =
      [route(), route(), failing_route]

    exception =
      assert_raise RuntimeError, fn -> Translations.transform(routes, RtxBackend, nil) end

    assert exception.message =~ "neither :language nor :locale was found"
  end

  test "should raise when no :language and invalid :locale attribute is set in a route" do
    routes =
      [route(%{locale: "en/US"}), route(), route()]

    exception =
      assert_raise RuntimeError, fn -> Translations.transform(routes, RtxBackend, nil) end

    assert exception.message =~
             ":locale `en/US` is a non supported format. Found in private.routex of route %Phoenix.Router.Route{"
  end

  test "should translate routes based on :language attribute" do
    routes =
      [
        route(%{language: "nl"}),
        route(%{language: "en"})
      ]

    assert [%Route{path: "/producten/:id"}, %Route{path: "/products/:id"}] =
             Translations.transform(routes, RtxBackend, nil)
  end

  test "should translate routes based on :locale attribute" do
    routes =
      [
        route(%{locale: "nl-NL"}),
        route(%{locale: "en-US"})
      ]

    assert [%Route{path: "/producten/:id"}, %Route{path: "/products/:id"}] =
             Translations.transform(routes, RtxBackend, nil)
  end

  test "should translate routes based on short :locale attribute" do
    routes =
      [
        route(%{locale: "nl"}),
        route(%{locale: "en"})
      ]

    assert [%Route{path: "/producten/:id"}, %Route{path: "/products/:id"}] =
             Translations.transform(routes, RtxBackend, nil)
  end

  test "should create Gettext triggers only for segments original routes" do
    routes =
      [
        %Route{
          path: "/producten/:id",
          private: %{routex: %{__branch__: [0, 1], locale: "nl"}}
        },
        %Route{
          path: "/products/:id",
          private: %{routex: %{__branch__: [0, 0], locale: "en"}}
        }
      ]

    ast = Translations.create_helpers(routes, RtxBackend, __ENV__)
    assert Macro.to_string(ast) =~ "products"
    refute Macro.to_string(ast) =~ "producten"
  end
end
