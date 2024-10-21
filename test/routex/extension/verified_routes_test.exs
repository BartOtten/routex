modules = [
  Phoenix.VerifiedRoutesTest.PostController,
  Phoenix.VerifiedRoutesTest.UserController
]

for module <- modules do
  defmodule module do
    def init(opts), do: opts
    def call(conn, _opts), do: conn
  end
end

defmodule RtxBackend do
  use Routex.Backend,
    extensions: [Routex.Extension.VerifiedRoutes],
    verified_sigil_routex: "~p",
    verified_sigil_original: "~o"
end

defmodule AdminRouter do
  use Phoenix.Router

  get "/dashboard", Phoenix.VerifiedRoutesTest.UserController, :index
end

defmodule Router do
  use Routex.Router
  use Phoenix.Router
  alias Phoenix.VerifiedRoutesTest.{PostController, UserController}

  preprocess_using RtxBackend do
    get "/posts/top", PostController, :top
    get "/posts/bottom/:order/:count", PostController, :bottom
    get "/posts/:id", PostController, :show
    get "/alt1/:id/postsa/", PostController, :show
    get "/alt2/:id/postsb/", PostController, :show
    get "/posts/:id/info", PostController, :show
    get "/posts/file/*file", PostController, :file
    get "/posts/skip", PostController, :skip
    get "/should-warn/*all", PostController, :all, warn_on_verify: true

    scope "/", host: "users." do
      post "/host_users/:id/info", UserController, :create
    end

    scope "/admin/new" do
      resources "/messages", PostController
    end

    get "/", PostController, :root
    get "/alt1", PostController, :root
    get "/alt2", PostController, :root

    forward "/router_forward", AdminRouter
    forward "/plug_forward", UserController
  end
end

defmodule CatchAllWarningRouter do
  use Phoenix.Router
  alias Phoenix.VerifiedRoutesTest.PostController

  get "/", PostController, :root
  get "/*path", PostController, :root, warn_on_verify: true
end

defmodule Routex.Extension.VerifiedRoutesTest do
  use ExUnit.Case, async: false
  import Plug.Test

  setup do
    set_branch(1)
    :ok
  end

  @derive {Phoenix.Param, key: :slug}
  defstruct [:id, :slug]

  # Emulate regular endpoint functions
  defmodule Endpoint do
    def url, do: "https://example.com"
    def static_url, do: "https://static.example.com"
    def path(path), do: path
    def static_path(path), do: path
    def static_integrity(_path), do: nil
  end

  defmodule ScriptName do
    def url, do: "https://example.com"
    def static_url, do: "https://static.example.com"
    def path(path), do: "/api" <> path
    def static_path(path), do: "/api" <> path
  end

  defmodule StaticPath do
    def url, do: "https://example.com"
    def static_url, do: "https://example.com"
    def path(path), do: path
    def static_path(path), do: "/static" <> path
    def static_integrity(_path), do: nil
  end

  defp conn_with_endpoint(endpoint \\ Endpoint) do
    conn(:get, "/")
    |> Plug.Conn.put_private(:phoenix_endpoint, endpoint)
    |> Plug.Conn.put_private(:routex, %{__branch__: [0, 1]})
  end

  defp socket_with_endpoint(endpoint \\ Endpoint),
    do: %Phoenix.Socket{endpoint: endpoint, private: %{routex: %{__branch__: [0, 1]}}}

  def conn_with_script_name(script_name \\ ~w(api)) do
    conn =
      Plug.Conn.put_private(conn(:get, "/"), :phoenix_endpoint, ScriptName)
      |> Plug.Conn.put_private(:routex, %{__branch__: [0, 1]})

    put_in(conn.script_name, script_name)
  end

  defp uri_with_script_name do
    %URI{scheme: "https", host: "example.com", port: 123, path: "/api"}
  end

  defp set_branch(nr), do: Process.put(:rtx_branch, nr)

  # Overwrite the Phoenix generated route structs to mimick other extenstions'
  # transformations. See how the original route `posts` is made a alternative
  # for `postsa` and gets the branch `1`. This aligns with the process key in the
  # setup function. This way we can use the original test cases from Phoenix
  # VerifiedRoutes.
  @routes [
    %Phoenix.Router.Route{
      path: "/",
      kind: :match,
      private: %{routex: %{__branch__: [0, 1], __origin__: "/"}}
    },
    %Phoenix.Router.Route{
      path: "/alt1",
      kind: :match,
      private: %{routex: %{__branch__: [0, 0], __origin__: "/"}}
    },
    %Phoenix.Router.Route{
      path: "/alt2",
      kind: :match,
      private: %{routex: %{__branch__: [0, 2], __origin__: "/"}}
    },
    %Phoenix.Router.Route{
      path: "/posts",
      kind: :match,
      private: %{routex: %{__branch__: [1, 1], __origin__: "/posts"}}
    },
    %Phoenix.Router.Route{
      path: "/alt1/postsa/",
      kind: :match,
      private: %{routex: %{__branch__: [1, 0], __origin__: "/posts"}}
    },
    %Phoenix.Router.Route{
      path: "/alt2/postsb/",
      kind: :match,
      private: %{routex: %{__branch__: [1, 2], __origin__: "/posts"}}
    },
    %Phoenix.Router.Route{
      path: "/posts/:id",
      kind: :match,
      private: %{routex: %{__branch__: [2, 1], __origin__: "/posts/:id"}}
    },
    %Phoenix.Router.Route{
      path: "/alt1/:id/postsa/",
      kind: :match,
      private: %{routex: %{__branch__: [2, 0], __origin__: "/posts/:id"}}
    },
    %Phoenix.Router.Route{
      path: "/alt2/:id/postsb/",
      kind: :match,
      private: %{routex: %{__branch__: [2, 2], __origin__: "/posts/:id"}}
    }
  ]

  macros_ast = Routex.Extension.VerifiedRoutes.create_helpers(@routes, RtxBackend, __ENV__)

  Code.compiler_options(ignore_module_conflict: true)
  Module.create(Router.RoutexHelpers, macros_ast, __ENV__)
  Code.compiler_options(ignore_module_conflict: false)

  use Phoenix.VerifiedRoutes, statics: ~w(images), endpoint: Endpoint, router: Router

  # here comes Routex
  import Phoenix.VerifiedRoutes, only: :functions
  import Router.RoutexHelpers

  test "~p preserves path separators from the new route definition" do
    set_branch(2)
    assert ~p"/posts/1" == "/alt2/1/postsb/"
    assert ~p"/posts/1?foo=bar" == "/alt2/1/postsb/?foo=bar"
  end

  test "~p with static string, using fallback branch 0" do
    Process.delete(:rtx_branch)
    assert ~p"/posts/1" == "/alt1/1/postsa/"
    assert ~p"/posts/1?foo=bar" == "/alt1/1/postsa/?foo=bar"
  end

  test "~p with static string" do
    assert ~p"/posts/1" == "/posts/1"
    assert ~p"/posts/1?foo=bar" == "/posts/1?foo=bar"
  end

  test "~p with dynamic string uses Phoenix.Param" do
    struct = %__MODULE__{id: 123, slug: "post-123"}
    assert ~p"/posts/#{struct}" == "/posts/post-123"
    assert ~p"/posts/#{123}" == "/posts/123"
    assert ~p|/posts/#{"a b"}| == "/posts/a%20b"
  end

  test "~p with static and dynamic string and query params" do
    struct = %__MODULE__{id: 123, slug: "post-123"}

    # static segments
    assert ~p"/posts/1?foo=bar" == "/posts/1?foo=bar"
    assert ~p"/posts/bottom/asc/10?foo=bar" == "/posts/bottom/asc/10?foo=bar"
    assert path(conn_with_endpoint(), ~p"/posts/1?foo=bar") == "/posts/1?foo=bar"
    assert path(@endpoint, @router, ~p"/posts/1?foo=bar") == "/posts/1?foo=bar"

    assert path(conn_with_endpoint(), ~p"/posts/bottom/asc/10?foo=bar") ==
             "/posts/bottom/asc/10?foo=bar"

    assert path(@endpoint, @router, ~p"/posts/bottom/asc/10?foo=bar") ==
             "/posts/bottom/asc/10?foo=bar"

    # dynamic segments
    assert ~p"/posts/#{struct}?#{[page: 1, spaced: "a b"]}" == "/posts/post-123?page=1&spaced=a+b"
    assert ~p"/posts/#{struct}?#{[page: 1, spaced: "a b"]}" == "/posts/post-123?page=1&spaced=a+b"
    id = 123
    dir = "asc"
    assert ~p"/posts/#{id}?foo=bar" == "/posts/123?foo=bar"
    assert ~p"/posts/post-#{id}?foo=bar" == "/posts/post-123?foo=bar"
    assert path(conn_with_endpoint(), ~p"/posts/#{id}?foo=bar") == "/posts/123?foo=bar"
    assert path(@endpoint, @router, ~p"/posts/#{id}?foo=bar") == "/posts/123?foo=bar"

    assert path(conn_with_endpoint(), ~p"/posts/bottom/#{dir}/#{id}?foo=bar") ==
             "/posts/bottom/asc/123?foo=bar"

    assert path(@endpoint, @router, ~p"/posts/bottom/#{dir}/#{id}?foo=bar") ==
             "/posts/bottom/asc/123?foo=bar"

    # dynamic query params
    assert ~p"/posts/1?other_post=#{id}" == "/posts/1?other_post=123"
    assert ~p"/posts/1?other_post=#{struct}" == "/posts/1?other_post=post-123"
  end

  test "~p with dynamic string and static query params" do
    struct = %__MODULE__{id: 123, slug: "post-123"}
    assert ~p"/posts/#{struct}?foo=bar" == "/posts/post-123?foo=bar"
  end

  test "~p with branchd host" do
    assert ~p"/host_users/1/info" == "/host_users/1/info"
  end

  test "~p on splat segments" do
    assert ~p|/posts/file/#{1}/#{"2.jpg"}| == "/posts/file/1/2.jpg"

    location = ["folder", "file.jpg"]
    assert ~p|/posts/file/#{location}| == "/posts/file/folder/file.jpg"
  end

  test "~p URI encodes interpolated segments and query params" do
    assert ~p"/posts/my path?#{[foo: "my param"]}" == "/posts/my%20path?foo=my+param"
    slug = "my path"
    assert ~p"/posts/#{slug}?#{[foo: "my param"]}" == "/posts/my%20path?foo=my+param"
  end

  test "~p with empty query string drops ?" do
    assert ~p"/posts/5?#{%{}}" == "/posts/5"
  end

  test "~p with hash" do
    assert ~p"/posts/123/info#bar" == "/posts/123/info#bar"

    warnings =
      ExUnit.CaptureIO.capture_io(:stderr, fn ->
        defmodule Hash do
          use Phoenix.VerifiedRoutes, endpoint: unquote(@endpoint), router: unquote(@router)
          import Phoenix.VerifiedRoutes, only: []

          def test, do: ~p"/posts/123/info#bar"
        end
      end)

    assert warnings == ""
  end

  test "~p raises on leftover sigil" do
    assert_raise ArgumentError, "~p does not support modifiers after closing, got: foo", fn ->
      defmodule LeftOver do
        use Phoenix.VerifiedRoutes, endpoint: unquote(@endpoint), router: unquote(@router)
        import Phoenix.VerifiedRoutes, only: []
        def test, do: ~p"/posts/1"foo
      end
    end
  end

  test "~p raises on dynamic interpolation" do
    msg = ~S|a dynamic ~p interpolation must follow a static segment, got: "/posts/#{1}#{2}"|

    assert_raise ArgumentError, msg, fn ->
      defmodule DynamicDynamic do
        use Phoenix.VerifiedRoutes, endpoint: unquote(@endpoint), router: unquote(@router)
        import Phoenix.VerifiedRoutes, only: []
        def test, do: ~p"/posts/#{1}#{2}"
      end
    end
  end

  # test "~p raises when not prefixed by /" do
  #   assert_raise ArgumentError,
  #                ~s|paths must begin with /, got: "posts/1"|,
  #                fn ->
  #                  defmodule SigilPPrefix do
  #                    use Phoenix.VerifiedRoutes,
  #                      endpoint: unquote(@endpoint),
  #                      router: unquote(@router)

  #                    import Phoenix.VerifiedRoutes, only: []

  #                    def test, do: ~p"posts/1"
  #                  end
  #                end
  # end

  test "path arities" do
    assert path(Endpoint, ~p"/posts/1") == "/posts/1"
    assert path(conn_with_endpoint(), ~p"/posts/1") == "/posts/1"
    assert path(conn_with_script_name(), ~p"/posts/1") == "/api/posts/1"
  end

  test "url arities" do
    assert url(~p"/posts/1") == "https://example.com/posts/1"
    assert url(~p"/posts/#{123}") == "https://example.com/posts/123"
    assert url(Endpoint, ~p"/posts/1") == "https://example.com/posts/1"
    assert url(conn_with_endpoint(), ~p"/posts/1") == "https://example.com/posts/1"
    assert url(conn_with_script_name(), ~p"/posts/1") == "https://example.com/api/posts/1"

    assert url(Endpoint, Router, ~p"/posts/1") == "https://example.com/posts/1"
    assert url(conn_with_endpoint(), Router, ~p"/posts/1") == "https://example.com/posts/1"
    assert url(conn_with_script_name(), Router, ~p"/posts/1") == "https://example.com/api/posts/1"
  end

  test "path raises when non ~p is passed" do
    assert_raise ArgumentError, ~r|expected compile-time ~p path string, got: "/posts/1"|, fn ->
      defmodule MissingPathPrefix do
        use Phoenix.VerifiedRoutes, endpoint: unquote(@endpoint), router: unquote(@router)
        import Phoenix.VerifiedRoutes, only: []
        def test, do: path(%URI{}, "/posts/1")
      end
    end
  end

  test "url raises when non ~p is passed" do
    assert_raise ArgumentError, ~r|expected compile-time ~p path string, got: "/posts/1"|, fn ->
      defmodule MissingURLPrefix do
        use Phoenix.VerifiedRoutes, endpoint: unquote(@endpoint), router: unquote(@router)
        import Phoenix.VerifiedRoutes, only: []
        def test, do: url("/posts/1")
      end
    end
  end

  test "static_integrity" do
    assert is_nil(static_integrity(Endpoint, "/images/foo.png"))
    assert is_nil(static_integrity(conn_with_endpoint(), "/images/foo.png"))
    assert is_nil(static_integrity(socket_with_endpoint(), "/images/foo.png"))
  end

  test "static paths" do
    assert path(Endpoint, ~p"/images/foo.png") == "/images/foo.png"
    assert path(conn_with_endpoint(), ~p"/images/foo.png") == "/images/foo.png"
    assert path(socket_with_endpoint(), ~p"/images/foo.png") == "/images/foo.png"
  end

  test "~p dict query strings" do
    assert ~p"/posts/5?#{[id: 3]}" == "/posts/5?id=3"
    assert ~p"/posts/5?#{[foo: "bar"]}" == "/posts/5?foo=bar"
    assert ~p"/posts/5?#{[foo: :bar]}" == "/posts/5?foo=bar"
    assert ~p"/posts/5?#{[foo: true]}" == "/posts/5?foo=true"
    assert ~p"/posts/5?#{[foo: false]}" == "/posts/5?foo=false"
    assert ~p"/posts/5?#{[foo: nil]}" == "/posts/5?foo="

    assert ~p"/posts/5?#{[foo: ~w(bar baz)]}" ==
             "/posts/5?foo[]=bar&foo[]=baz"

    assert ~p"/posts/5?#{[foo: %{id: 5}]}" ==
             "/posts/5?foo[id]=5"

    assert ~p"/posts/5?#{[foo: %{__struct__: Foo, id: 5}]}" ==
             "/posts/5?foo=5"
  end

  test "~p mixed query string interpolation" do
    dir = "asc"
    page = "pg"

    assert ~p"/posts/5?page=#{3}" == "/posts/5?page=3"
    assert ~p"/posts/5?page=#{3}&dir=#{dir}" == "/posts/5?page=3&dir=asc"
    assert ~p"/posts/5?#{page}=#{3}&dir=#{dir}" == "/posts/5?pg=3&dir=asc"
    assert ~p"/posts/5?#{"a b"}=#{3}&dir=#{"a b"}" == "/posts/5?a+b=3&dir=a+b"

    assert ~p"/posts/post?foo=bar&#{"key"}=#{"val"}&baz=bat" ==
             "/posts/post?foo=bar&key=val&baz=bat"

    assert ~p"/posts/#{page}?foo=bar&#{"key"}=#{"val"}&baz=bat" ==
             "/posts/pg?foo=bar&key=val&baz=bat"
  end

  test "invalid mixed interpolation query string raises" do
    msg =
      ~S|interpolated query string params must be separated by &, got: "/posts/5?page=#{3}#{dir}"|

    assert_raise ArgumentError, msg, fn ->
      defmodule InvalidQuery do
        use Phoenix.VerifiedRoutes,
          endpoint: unquote(@endpoint),
          router: unquote(@router)

        import Phoenix.VerifiedRoutes, only: []

        def test do
          ~p"/posts/5?page=#{3}#{dir}" == "/posts/5?page=3"
        end
      end
    end
  end

  test "~p with complex ids" do
    assert ~p|/posts/#{"==d--+"}| == "/posts/%3D%3Dd--%2B"
    assert ~p|/posts/top?#{[id: "==d--+"]}| == "/posts/top?id=%3D%3Dd--%2B"

    assert ~p|/posts/file/#{"==d--+"}/#{":O.jpg"}| == "/posts/file/%3D%3Dd--%2B/%3AO.jpg"

    assert ~p|/posts/file/#{"==d--+"}/#{":O.jpg"}?#{[xx: "/=+/"]}| ==
             "/posts/file/%3D%3Dd--%2B/%3AO.jpg?xx=%2F%3D%2B%2F"
  end

  test "~p with trailing slashes" do
    assert ~p"/posts/5/" == "/posts/5/"
    assert ~p"/posts/5/?#{[id: 5]}" == "/posts/5/?id=5"
    assert ~p"/posts/5/?#{%{"id" => "foo"}}" == "/posts/5/?id=foo"
    assert ~p"/posts/5/?#{%{"id" => "foo bar"}}" == "/posts/5/?id=foo+bar"
  end

  describe "with static path" do
    @endpoint StaticPath
    @router Router
    test "paths use static prefix" do
      assert ~p"/images/foo.png" == "/static/images/foo.png"

      assert path(conn_with_endpoint(StaticPath), ~p"/images/foo.png") ==
               "/static/images/foo.png"

      assert path(socket_with_endpoint(StaticPath), ~p"/images/foo.png") ==
               "/static/images/foo.png"

      assert url(conn_with_endpoint(StaticPath), ~p"/images/foo.png") ==
               "https://example.com/static/images/foo.png"

      assert url(socket_with_endpoint(StaticPath), ~p"/images/foo.png") ==
               "https://example.com/static/images/foo.png"
    end
  end

  describe "with script name" do
    @endpoint ScriptName
    @router Router

    test "paths use script name" do
      assert ~p"/" == "/api/"
      assert path(ScriptName, Router, ~p"/") == "/api/"
      assert path(conn_with_script_name(), ~p"/") == "/api/"
      assert path(uri_with_script_name(), ~p"/") == "/api/"
      assert path(ScriptName, Router, ~p"/posts/5") == "/api/posts/5"
      assert ~p"/posts/5" == "/api/posts/5"
      assert path(ScriptName, Router, ~p"/posts/#{123}") == "/api/posts/123"
      assert ~p"/posts/#{123}" == "/api/posts/123"
      assert path(uri_with_script_name(), ~p"/posts/5") == "/api/posts/5"
      assert path(uri_with_script_name(), ~p"/posts/#{123}") == "/api/posts/123"
    end

    test "urls use script name" do
      assert url(ScriptName, ~p"/") == "https://example.com/api/"
      assert url(conn_with_script_name(~w(foo)), ~p"/") == "https://example.com/foo/"
      assert url(uri_with_script_name(), ~p"/") == "https://example.com:123/api/"
      assert url(ScriptName, ~p"/posts/5") == "https://example.com/api/posts/5"
      assert url(ScriptName, ~p"/posts/#{123}") == "https://example.com/api/posts/123"
      assert url(conn_with_script_name(), ~p"/posts/5") == "https://example.com/api/posts/5"

      assert url(conn_with_script_name(~w(foo)), ~p"/posts/5") ==
               "https://example.com/foo/posts/5"

      assert url(uri_with_script_name(), ~p"/posts/5") == "https://example.com:123/api/posts/5"
    end

    test "static use endpoint script name only" do
      assert path(conn_with_script_name(~w(foo)), ~p"/images/foo.png") ==
               "/api/images/foo.png"

      assert url(conn_with_script_name(~w(foo)), ~p"/images/foo.png") ==
               "https://static.example.com/api/images/foo.png"
    end

    test "phoenix_router_url with string takes precedence over endpoint" do
      url = "https://phoenixframework.org"
      conn = Phoenix.Controller.put_router_url(conn_with_endpoint(), url)

      assert url(conn, ~p"/") == url <> "/"
      assert url(conn, ~p"/admin/new/messages/1") == url <> "/admin/new/messages/1"
      assert url(conn, ~p"/admin/new/messages/#{123}") == url <> "/admin/new/messages/123"
    end

    test "phoenix_router_url with URI takes precedence over endpoint" do
      uri = %URI{scheme: "https", host: "phoenixframework.org", port: 123, path: "/path"}
      conn = Phoenix.Controller.put_router_url(conn_with_endpoint(), uri)

      assert url(conn, ~p"/") == "https://phoenixframework.org:123/path/"

      assert url(conn, ~p"/admin/new/messages/1") ==
               "https://phoenixframework.org:123/path/admin/new/messages/1"
    end

    test "phoenix_static_url with string takes precedence over endpoint" do
      url = "https://phoenixframework.org"

      conn = Phoenix.Controller.put_static_url(conn_with_endpoint(), url)
      assert url(conn, ~p"/images/foo.png") == url <> "/images/foo.png"

      conn = Phoenix.Controller.put_static_url(conn_with_script_name(), url)
      assert url(conn, ~p"/images/foo.png") == url <> "/images/foo.png"
    end

    test "phoenix_static_url set to string with path results in static url with that path" do
      url = "https://phoenixframework.org/path"
      conn = Phoenix.Controller.put_static_url(conn_with_endpoint(), url)
      assert url(conn, ~p"/images/foo.png") == url <> "/images/foo.png"

      conn = Phoenix.Controller.put_static_url(conn_with_script_name(), url)
      assert url(conn, ~p"/images/foo.png") == url <> "/images/foo.png"
    end

    test "phoenix_static_url with URI takes precedence over endpoint" do
      uri = %URI{scheme: "https", host: "phoenixframework.org", port: 123}

      conn = Phoenix.Controller.put_static_url(conn_with_endpoint(), uri)
      assert url(conn, ~p"/images/foo.png") == "https://phoenixframework.org:123/images/foo.png"

      conn = Phoenix.Controller.put_static_url(conn_with_script_name(), uri)
      assert url(conn, ~p"/images/foo.png") == "https://phoenixframework.org:123/images/foo.png"
    end

    test "phoenix_static_url set to URI with path results in static url with that path" do
      uri = %URI{scheme: "https", host: "phoenixframework.org", port: 123, path: "/path"}

      conn = Phoenix.Controller.put_static_url(conn_with_endpoint(), uri)

      assert url(conn, ~p"/images/foo.png") ==
               "https://phoenixframework.org:123/path/images/foo.png"

      conn = Phoenix.Controller.put_static_url(conn_with_script_name(), uri)

      assert url(conn, ~p"/images/foo.png") ==
               "https://phoenixframework.org:123/path/images/foo.png"
    end
  end

  # if Version.match?(System.version(), ">= 1.14.0-dev") do
  #   describe "warnings" do
  #     test "forwards" do
  #       warnings =
  #         ExUnit.CaptureIO.capture_io(:stderr, fn ->
  #           defmodule Forwards do
  #             use Phoenix.VerifiedRoutes, endpoint: unquote(@endpoint), router: unquote(@router)
  #             import Phoenix.VerifiedRoutes, only: []

  #             def test do
  #               "/router_forward/dashboard" = ~p"/router_forward/dashboard"
  #               "/router_forward/warn" = ~p"/router_forward/warn"
  #               "/plug_forward/home" = ~p"/plug_forward/home"
  #             end
  #           end
  #         end)

  #       line = __ENV__.line - 6

  #       warnings = String.replace(warnings, ~r/(\x9B|\x1B\[)[0-?]*[ -\/]*[@-~]/, "")

  #       assert warnings =~
  #                "warning: no route path for Router matches \"/router_forward/warn\"\n     │\n #{line} │                   \"/router_forward/warn\" = ~p\"/router_forward/warn\"\n     │                                              ~\n     │\n     └─ test/routex/extension/verified_routes_test.exs:#{line}: Routex.Extension.VerifiedRoutesTest.Forwards.test/0\n\n"
  #     end

  #     test "~p warns on unmatched path" do
  #       warnings =
  #         ExUnit.CaptureIO.capture_io(:stderr, fn ->
  #           defmodule Unmatched do
  #             use Phoenix.VerifiedRoutes, endpoint: unquote(@endpoint), router: unquote(@router)
  #             import Phoenix.VerifiedRoutes, only: []

  #             def test do
  #               ~p"/unknown"
  #               ~p"/unknown/123"
  #               ~p"/unknown/#{123}"
  #             end
  #           end
  #         end)

  #       assert warnings =~
  #                ~s|no route path for Router matches "/unknown"|

  #       assert warnings =~
  #                ~s|no route path for Router matches "/unknown/123"|

  #       assert warnings =~
  #                ~s|no route path for Router matches "/unknown/#{123}"|
  #     end

  # test "~p warns on warn_on_verify: true route" do
  #   warnings =
  #     ExUnit.CaptureIO.capture_io(:stderr, fn ->
  #       defmodule VerifyFalse do
  #         use Phoenix.VerifiedRoutes, endpoint: unquote(@endpoint), router: unquote(@router)

  #         def test, do: ~p"/should-warn/foobar"
  #       end
  #     end)

  #   assert warnings =~
  #            ~s|no route path for Router matches "/should-warn/foobar"|
  # end

  # test "~p does not warn if route without warn_on_verify: true matches first" do
  #   warnings =
  #     ExUnit.CaptureIO.capture_io(:stderr, fn ->
  #       defmodule VerifyFalseTrueMatchableesFirst do
  #         use Phoenix.VerifiedRoutes,
  #           endpoint: unquote(@endpoint),
  #           router: CatchAllWarningRouter

  #         def test, do: ~p"/"
  #       end
  #     end)

  #   assert warnings == ""
  # end
  # end
  # end

  # end

  # #   test "should print a message when ~p is used by Routex" do
  # #     url(~p"/home") |> IO.inspect()
  # #   end

  # #   test "should print a message when anoth sigil is used" do
  # #   end

  # #   test "should set assigned sigils in config" do
  # #   end

  # #   test "should create original sigil helper when overridden" do
  # #   end

  # #   test "should not create original sigil helper when it's not overridden" do
  # #   end

  # #   test "should create branching url/{2,3,4}" do
  # #   end

  # #   test "should create delegating url/{2,3,4}" do
  # #   end

  # #   test "should create branching path/{2,3}" do
  # #   end

  # #   test "should create delegating path/{2,3}" do
  # #   end
  # #
end
