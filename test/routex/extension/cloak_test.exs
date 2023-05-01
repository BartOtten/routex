defmodule Routex.Extension.CloakTest do
  use ExUnit.Case, async: true

  require ListAssertions
  alias Routex.Extension.Cloak

  defmodule Conf1 do
    use(Routex, extensions: [Routex.Extension.Cloak], cloak_character: ".")
  end

  test "simple test" do
    routes = [
      %Phoenix.Router.Route{path: "/foo"},
      %Phoenix.Router.Route{path: "/foo/:id"},
      %Phoenix.Router.Route{path: "/bar"},
      %Phoenix.Router.Route{path: "/bar/show/:id"},
      %Phoenix.Router.Route{path: "/bar/:id"},
      %Phoenix.Router.Route{path: "/bar/:id/edit"}
    ]

    new = Cloak.transform(routes, Conf1, nil)

    ListAssertions.assert_unordered(
      [
        %{path: "/c"},
        %{path: "/c/:id/1"},
        %{path: "/c/2"},
        %{path: "/c/:id/3"},
        %{path: "/c/:id/4"},
        %{path: "/c/:id/5"}
      ],
      new
    )
  end
end
