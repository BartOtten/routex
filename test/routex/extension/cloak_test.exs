defmodule Routex.Extension.CloakTest do
  use ExUnit.Case, async: true

  require ListAssertions
  alias Routex.Extension.Cloak

  defmodule Conf1 do
    use(Routex.Backend, extensions: [Routex.Extension.Cloak], cloak_character: ".")
  end

  test "should cloak routes" do
    routes = [
      %Phoenix.Router.Route{path: "/foo"},
      %Phoenix.Router.Route{path: "/foo/:id"},
      %Phoenix.Router.Route{path: "/bar"},
      %Phoenix.Router.Route{path: "/bar/show/:id"},
      %Phoenix.Router.Route{path: "/bar/:id"},
      %Phoenix.Router.Route{path: "/bar/:id/edit"},
      # triggers duplicate check
      %Phoenix.Router.Route{path: "/foo"}
    ]

    transformed_routes = Cloak.transform(routes, Conf1, nil)

    ListAssertions.assert_unordered(
      [
        %{path: "/"},
        %{path: "/:id/1"},
        %{path: "/2"},
        %{path: "/:id/3"},
        %{path: "/:id/4"},
        %{path: "/:id/5"}
      ],
      transformed_routes
    )
  end
end
