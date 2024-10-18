defmodule Routex.Extension.Alternatives.Config do
  @moduledoc """
  Module to create and validate a Config struct
  """
  # credo:disable-for-next-line
  alias Routex.Extension.Alternatives, as: PLR
  alias PLR.Exceptions
  alias PLR.Branch
  alias PLR.Branches

  @type t :: %__MODULE__{
          branches: %{(binary | nil) => Routex.Extension.Alternatives.Branch.Flat.t()}
        }
  @typep branch :: Branch.Flat.t()
  @typep branch_tuple :: {binary | nil, branch}

  @enforce_keys [:branches]
  defstruct [:branches]

  @doc false
  @spec new!(keyword) :: t()
  def new!(opts) do
    branches_flat = opts |> Keyword.get(:branches_nested) |> Branches.flatten()

    __MODULE__
    |> struct(%{
      branches: branches_flat
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

  # checks whether the branches has a top level "/" (root) slug
  @doc false
  @spec validate_root_slug!(t) :: t
  def validate_root_slug!(%__MODULE__{branches: branches} = opts) do
    unless Enum.any?(branches, fn {_branch, branch_opts} -> branch_opts.branch_prefix == "/" end),
      do: raise(Exceptions.MissingRootSlugError)

    opts
  end

  # attribute keys should match in order to have uniform availability
  @doc false
  @spec validate_matching_attribute_keys!(t) :: t
  def validate_matching_attribute_keys!(
        %__MODULE__{branches: %{nil: reference_branch} = branches} = opts
      ) do
    reference_keys = get_sorted_attributes_keys(reference_branch)

    Enum.each(branches, fn
      {nil, ^reference_branch} = _reference_branch ->
        :noop

      branch ->
        ^branch = validate_matching_attribute_keys!(branch, reference_keys)
    end)

    opts
  end

  @doc false
  @spec validate_matching_attribute_keys!(branch_tuple, list(atom | binary)) :: branch_tuple
  def validate_matching_attribute_keys!({key, branch_opts} = branch, reference_keys) do
    attributes_keys = get_sorted_attributes_keys(branch_opts)

    if attributes_keys != reference_keys,
      do:
        raise(Exceptions.AttrsMismatchError,
          branch: key,
          expected_keys: reference_keys,
          actual_keys: attributes_keys
        )

    branch
  end

  @spec get_sorted_attributes_keys(map) :: list()
  defp get_sorted_attributes_keys(%{attrs: attributes}) when is_map(attributes),
    do: attributes |> Map.keys() |> Enum.sort()

  defp get_sorted_attributes_keys(_branch_opts), do: []
end
