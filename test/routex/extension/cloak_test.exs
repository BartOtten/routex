defmodule Routex.Extension.CloakTest do
  use ExUnit.Case, async: true

  require ListAssertions
  alias Routex.Extension.Cloak

  defmodule Conf1 do
    use(Routex.Backend, extensions: [Routex.Extension.Cloak])
  end

  defmodule Conf2 do
    use(Routex.Backend, extensions: [Routex.Extension.Cloak], cloak: ".")
  end

  test "should cloak routes" do
    routes = [
      %Phoenix.Router.Route{path: "/"},
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
        %{path: "/1"},
        %{path: "/:id/2"},
        %{path: "/3"},
        %{path: "/:id/4"},
        %{path: "/:id/5"},
        %{path: "/:id/6"}
      ],
      transformed_routes
    )

    more_transformed_routes = Cloak.transform(routes, Conf2, nil)

    ListAssertions.assert_unordered(
      [
        %{path: "/"},
        %{path: "/.."},
        %{path: "/:id/..."},
        %{path: "/...."},
        %{path: "/:id/....."},
        %{path: "/:id/......"},
        %{path: "/:id/......."}
      ],
      more_transformed_routes
    )
  end
end
