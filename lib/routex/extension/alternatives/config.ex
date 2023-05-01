defmodule Routex.Extension.Alternatives.Config do
  @moduledoc """
  Module to create and validate a Config struct
  """
  # credo:disable-for-next-line
  alias Routex.Extension.Alternatives, as: PLR
  alias PLR.Exceptions
  alias PLR.Scope
  alias PLR.Scopes

  @type t :: %__MODULE__{
          scopes: %{(binary | nil) => Routex.Extension.Alternatives.Scope.Flat.t()}
        }
  @typep scope :: Scope.Flat.t()
  @typep scope_tuple :: {binary | nil, scope}

  @enforce_keys [:scopes]
  defstruct [:scopes]

  @doc false
  @spec new!(keyword) :: t()
  def new!(opts) do
    scopes_flat = opts |> Keyword.get(:scopes_nested) |> Scopes.flatten()

    __MODULE__
    |> struct(%{
      scopes: scopes_flat
    })
    |> validate!()
  end

  @doc false
  @spec validate!(t) :: t
  def validate!(%__MODULE__{} = config) do
    ^config =
      config
      |> validate_root_slug!()
      |> validate_matching_attribute_keys!()
  end

  # checks whether the scopes has a top level "/" (root) slug
  @doc false
  @spec validate_root_slug!(t) :: t
  def validate_root_slug!(%__MODULE__{scopes: scopes} = opts) do
    unless Enum.any?(scopes, fn {_scope, scope_opts} -> scope_opts.scope_prefix == "/" end),
      do: raise(Exceptions.MissingRootSlugError)

    opts
  end

  # attribute keys should match in order to have uniform availability
  @doc false
  @spec validate_matching_attribute_keys!(t) :: t
  def validate_matching_attribute_keys!(
        %__MODULE__{scopes: %{nil: reference_scope} = scopes} = opts
      ) do
    reference_keys = get_sorted_attributes_keys(reference_scope)

    Enum.each(scopes, fn
      {nil, ^reference_scope} = _reference_scope ->
        :noop

      scope ->
        ^scope = validate_matching_attribute_keys!(scope, reference_keys)
    end)

    opts
  end

  @doc false
  @spec validate_matching_attribute_keys!(scope_tuple, list(atom | binary)) :: scope_tuple
  def validate_matching_attribute_keys!({key, scope_opts} = scope, reference_keys) do
    attributes_keys = get_sorted_attributes_keys(scope_opts)

    if attributes_keys != reference_keys,
      do:
        raise(Exceptions.AttrsMismatchError,
          scope: key,
          expected_keys: reference_keys,
          actual_keys: attributes_keys
        )

    scope
  end

  @spec get_sorted_attributes_keys(map) :: list()
  defp get_sorted_attributes_keys(%{attrs: attributes}) when is_map(attributes),
    do: attributes |> Map.keys() |> Enum.sort()

  defp get_sorted_attributes_keys(_scope_opts), do: []
end
