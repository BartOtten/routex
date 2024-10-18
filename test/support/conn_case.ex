defmodule MyAppWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.
  """
  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import MyAppWeb.ConnCase

      alias MyAppWeb.Router.Helpers, as: Routes

      # The default endpoint for testing
      @endpoint MyAppWeb.Endpoint
    end
  end

  setup_all do
    start_supervised!({Phoenix.PubSub, name: MyApp.PubSub})
    start_supervised!(MyAppWeb.Endpoint)

    :ok
  end

  setup do
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
