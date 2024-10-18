defmodule Routex.ConfigTest do
  use ExUnit.Case

  alias Routex.Extension.Alternatives
  alias Alternatives.Config
  alias Alternatives.Branches
  alias Alternatives.Exceptions.AttrsMismatchError
  alias Alternatives.Exceptions.MissingRootSlugError

  describe "config new" do
    test "returns a Config struct" do
      branches_nested =
        Branches.add_precomputed_values!(%{
          "/" => %{
            attrs: %{key1: 1, key2: 2},
            branches: %{
              "/foo" => %{attrs: %{key1: 1, key2: 2}}
            }
          }
        })

      assert %Config{branches: %{nil => _, "foo" => _}} =
               Config.new!(branches_nested: branches_nested)
    end
  end

  describe "config validation" do
    test "raises when no root slug is set" do
      assert_raise MissingRootSlugError, fn ->
        Config.validate!(%Config{
          branches: %{nil => %{branch_prefix: "foo", attrs: %{key1: 1}}}
        })
      end
    end

    test "does not raise when no attributes" do
      config = %Config{
        branches: %{
          nil => %{
            branch_prefix: "/"
          },
          "foo" => %{}
        }
      }

      assert config == Config.validate!(config)
    end

    test "does not raise when attribute keys match" do
      matching_assign = %{key1: 1, key2: 2}

      config = %Config{
        branches: %{
          nil => %{
            branch_prefix: "/",
            attrs: matching_assign
          },
          "foo" => %{attrs: matching_assign}
        }
      }

      assert config == Config.validate!(config)
    end

    test "raises on assign keys mismatch" do
      assert_raise AttrsMismatchError, fn ->
        Config.validate!(%Config{
          branches: %{
            nil => %{
              branch_prefix: "/",
              attrs: %{key1: 1, key2: 2}
            },
            "foo" => %{attrs: %{key1: 1}}
          }
        })
      end
    end
  end
end
