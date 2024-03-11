defmodule Routex.Extension.Interpolation do
  @moduledoc ~S"""
  A route may be defined with a routes `Routex.Attrs` interpolated
  into it. These interpolations are specified using the normal #{}
  interpolation syntax.

  > #### In combination with... {: .info}
  > This plugin makes a good duo with `Routex.Extension.Alternatives`. You might
  > want to disable auto prefixing for the whole Routex backend (see
  > `Routex.Extension.Alternatives`) or per route (see `Routex`for
  > instructions).

  ## Usage
  ```diff
  # file /lib/example_web/routes.ex
  live "/products/#{locale}/:id", ProductLive.Index, :index
  ```

  ## Pseudo result
      # in combination with Routex.Extension.Alternatives with auto prefix
      # disabled and 3 scopes. It splits the routes and sets the :locale
      # attribute which is used for interpolation.

                               ⇒ /products/en/:id
      /products/#{locale}/:id/ ⇒ /products/fr/:id
                               ⇒ /products/fr/:id

  ## `Routex.Attrs`
  **Requires**
  - none

  **Sets**
  - none
  """

  defmodule NonUniqError do
    @moduledoc """
    Raised when a list of routes contains routes with the same path and verb.

    ```elixir
    [%Route{
      path: "/foo"
      verb: :get},
    %Route{
      path: "/foo"
      verb: :post}, # <-- different
    %Route{
      path: "/foo"
      verb: :get} # <-- duplicate
    ]
    ```

    Solution: use a combination of interpolated attributes that form a unique set.
    """

    defexception [:duplicated]

    @impl Exception
    def message(exception) do
      for {{_verb, path}, routes} <- exception.duplicated do
        origins =
          routes
          |> Enum.uniq_by(& &1.private.routex.__origin__)
          |> Enum.map(&"\n - line: #{&1.line}, path: #{&1.private.routex.__origin__}")

        duplicates =
          for route <- routes do
            "\n- #{inspect(route, pretty: true)}"
          end

        """
        Interpolation caused duplicated paths. Please make sure the set of interpolated values
        form a unique combination.

        Path: #{path}
        Origins: #{origins}
        Duplicates: #{duplicates}
        """
      end
      |> Enum.join("")
    end
  end

  alias Routex.Attrs
  require Logger

  @behaviour Routex.Extension
  @interpolate ~r/\[rtx\.(\w+)\]/

  @impl Routex.Extension
  def transform(routes, _backend, _env) do
    routes
    |> Enum.map(&interpolate/1)
    |> check_uniqness!()
  end

  defp interpolate(route) do
    path =
      Regex.replace(@interpolate, route.path, fn _full, c1 ->
        key = c1 |> String.to_atom()

        Attrs.get!(
          route,
          key,
          "#{route |> Attrs.get(:backend) |> to_string()} lists this extention but key :#{key} was not found in private.routex of route #{inspect(Macro.escape(route), pretty: true)}."
        )
        |> to_string()
      end)

    %{route | path: path}
  end

  defp check_uniqness!(routes) do
    duplicated =
      routes
      |> Enum.group_by(&{&1.verb, &1.path})
      |> Enum.filter(fn {{_verb, _path}, routes} -> length(routes) > 1 end)

    if duplicated != [], do: raise(NonUniqError, duplicated: duplicated)

    routes
  end
end
