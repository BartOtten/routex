defmodule Routex.Extension.Alternatives.Exceptions do
  defmodule AttrsMismatchError do
    @moduledoc """
    Raised when the custom attributes of branches do not have the same keys.

    ```elixir
    %{
      branches: %{
        "/"      => %{attrs: %{key1: 1, key2: 2}},
        "/other" => %{attrs: %{key1: 1}} # missing :key2
      }
    }
    ```

    To fix this, make the attribute maps consistent or use an attributes struct.
    """

    defexception [:branch, :expected_keys, :actual_keys]

    @impl Exception
    def message(exception) do
      ~s"""
      attribute keys mismatch in local branch #{exception.branch}.\n
      Expected: #{inspect(exception.expected_keys)}
      Actual: #{inspect(exception.actual_keys)}
      """
    end
  end

  defmodule MissingRootSlugError do
    @moduledoc """
    Raised when the branch map does not start with the root branch "/".

    ```elixir
    %{
      branches: %{
        "/first"  =>    %{attrs: %{key1: 1}},
        "/other"  =>    %{attrs: %{key1: 1}}},
    }
    ```

    To fix this, include a branch for the root "/".

    ```elixir
    `%{
      branches: %{
        "/" => %{
          attrs: %{level: 1}
          branches: %{
            "/first"  =>    %{attrs: %{level: 2}},
            "/other"  =>    %{attrs: %{level: 2}}
          }
        },
      }
    }
    ```

    """

    defexception message:
                   "the configured branches do not start with a root slug. Please wrap your branches in a root branch with key '/'"
  end
end
