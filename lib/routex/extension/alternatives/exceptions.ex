defmodule Routex.Extension.Alternatives.Exceptions do
  defmodule AttrsMismatchError do
    @moduledoc """
    Raised when the custom attributes of scopes do not have the same keys.

    ```elixir
    %{
      scopes: %{
        "/"      => %{attrs: %{key1: 1, key2: 2}},
        "/other" => %{attrs: %{key1: 1}} # missing :key2
      }
    }
    ```

    To fix this, make the attribute maps consistent or use an attributes struct.
    """

    defexception [:scope, :expected_keys, :actual_keys]

    @impl Exception
    def message(exception) do
      ~s"""
      attribute keys mismatch in local scope #{exception.scope}.\n
      Expected: #{inspect(exception.expected_keys)}
      Actual: #{inspect(exception.actual_keys)}
      """
    end
  end

  defmodule MissingRootSlugError do
    @moduledoc """
    Raised when the scope map does not start with the root scope "/".

    ```elixir
    %{
      scopes: %{
        "/first"  =>    %{attrs: %{key1: 1}},
        "/other"  =>    %{attrs: %{key1: 1}}},
    }
    ```

    To fix this, include a scope for the root "/".

    ```elixir
    `%{
      scopes: %{
        "/" => %{
          attrs: %{level: 1}
          scopes: %{
            "/first"  =>    %{attrs: %{level: 2}},
            "/other"  =>    %{attrs: %{level: 2}}
          }
        },
      }
    }
    ```

    """

    defexception message:
                   "the configured scopes do not start with a root slug. Please wrap your scopes in a root scope with key '/'"
  end
end
