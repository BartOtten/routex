defmodule Routex.Extension.Alternatives.Branch.Nested do
  @moduledoc """
  Struct for branch with optionally nested branches
  """
  @type t :: %__MODULE__{
          attrs: %{atom => any} | nil,
          branch_path: list(binary),
          branch_prefix: binary,
          branch_alias: atom,
          branches: %{(binary | atom) => t} | nil
        }

  defstruct [
    :branch_alias,
    attrs: %{},
    branch_path: [],
    branch_prefix: "",
    branches: %{}
  ]
end

defmodule Routex.Extension.Alternatives.Branch.Flat do
  @moduledoc """
  Struct for flattened branch
  """
  @type t :: %__MODULE__{
          attrs: %{atom => any} | nil,
          branch_path: list(binary),
          branch_prefix: binary,
          branch_alias: atom
        }

  defstruct [
    :branch_alias,
    attrs: %{},
    branch_path: [],
    branch_prefix: ""
  ]
end

defmodule Routex.Extension.Alternatives.Branches do
  @moduledoc false

  alias Routex.Extension.Alternatives.Branch

  @type branches :: %{(binary | nil) => Branch.Flat.t()}
  @type branches_nested :: %{(binary | nil) => Branch.Nested.t()}
  @type branches_nested_tuple :: {binary | nil, Branch.Nested.t()}
  @type branch_nested :: Branch.Nested.t()
  @type branch_tuple :: {binary | nil, Branch.Flat.t()}
  @type opts_branch :: %{
          optional(:attrs) => %{atom => any},
          optional(:branches) => %{binary => opts_branch}
        }

  # return a list of unique values attr to given key. Returns a list
  # of tuples with unique combinations when a list of keys is given.
  @spec attr_values(branches, atom | binary) :: list(any)
  def attr_values(branches, key) when is_atom(key) or is_binary(key),
    do: branches |> attr_values([key]) |> Stream.map(&elem(&1, 0)) |> Enum.uniq()

  @spec attr_values(branches, list(atom | binary)) :: list({atom | binary, any})
  def attr_values(branches, keys) when is_list(keys) do
    branches |> aggregate_attrs(keys) |> Enum.uniq()
  end

  # takes a nested map of maps and returns a flat map with concatenated keys, aliases and prefixes.
  @spec flatten(branches :: branches_nested) :: branches()
  def flatten(branches), do: branches |> do_flatten_branches() |> List.flatten() |> Map.new()

  @spec do_flatten_branches(branches_nested, nil | {binary, any} | {nil, nil}) ::
          list(branches)
  def do_flatten_branches(branches, parent \\ {nil, nil}) do
    Enum.reduce(branches, [], fn
      {_, branch_opts} = full_branch, acc ->
        new_branch = flatten_branch(full_branch, parent)
        flattened_subtree = do_flatten_branches(branch_opts.branches, new_branch)

        [[new_branch | flattened_subtree] | acc]
    end)
  end

  @spec flatten_branch(branches_nested_tuple(), branch_tuple) :: branch_tuple
  def flatten_branch({_branch, branch_opts}, {_p_branch, p_branch_opts})
      when is_nil(p_branch_opts) or is_nil(p_branch_opts.branch_alias) do
    branch_opts = Map.drop(branch_opts, [:branches])
    branch_key = branch_opts.attrs.branch_helper
    {branch_key, struct(Branch.Flat, Map.from_struct(branch_opts))}
  end

  def flatten_branch({_branch, branch_opts}, {_p_branch, p_branch_opts}) do
    flattened_branch_prefix = Path.join(p_branch_opts.branch_prefix, branch_opts.branch_prefix)

    flattened_branch_alias =
      String.to_atom(
        "#{Atom.to_string(p_branch_opts.branch_alias)}_#{Atom.to_string(branch_opts.branch_alias)}"
      )

    branch_opts = %{
      branch_opts
      | branch_prefix: flattened_branch_prefix,
        branch_alias: flattened_branch_alias
    }

    new_branch_opts = Map.drop(branch_opts, [:branches])
    new_branch_key = branch_opts.attrs.branch_helper

    {new_branch_key, struct(Branch.Flat, Map.from_struct(new_branch_opts))}
  end

  @spec get_slug_key(binary) :: binary
  def get_slug_key(slug), do: slug |> String.replace("/", "_") |> String.replace_prefix("_", "")

  @spec get_branch_opts(slug :: binary, list(binary)) :: %{
          key: nil | binary,
          path: list,
          prefix: binary,
          alias: nil | atom,
          helper: nil | binary
        }
  def get_branch_opts("/", []) do
    %{key: nil, path: [], prefix: "", alias: nil, helper: nil}
  end

  def get_branch_opts(slug, p_branch_path) when is_list(p_branch_path) do
    key = get_slug_key(slug)
    path = Enum.concat(p_branch_path, [key])

    %{
      key: key,
      path: path,
      prefix: slug |> String.replace(" ", "_"),
      alias: String.to_atom(key),
      helper: Enum.join(path, "_")
    }
  end

  @spec add_precomputed_values!(%{binary => opts_branch}, parent_branch :: branch_nested) ::
          branches_nested
  def add_precomputed_values!(branches, p_branch \\ %Branch.Nested{}) do
    for {slug, branch} <- branches, into: %{} do
      branch = Map.put_new(branch, :attrs, Map.new())
      branch_opts = get_branch_opts(slug, p_branch.branch_path)
      attrs_map = destruct(branch.attrs)

      new_attrs =
        p_branch.attrs
        |> Map.merge(attrs_map)
        |> Map.put(:branch_helper, branch_opts.helper)

      new_opts =
        maybe_compute_nested_branches(
          %Branch.Nested{
            attrs: new_attrs,
            branch_path: branch_opts.path,
            branch_prefix: Path.join("/", branch_opts.prefix),
            branch_alias: branch_opts.alias
          },
          branch
        )

      {branch_opts.key, new_opts}
    end
  end

  @spec destruct(map | struct) :: map
  def destruct(map_or_struct) when is_struct(map_or_struct), do: Map.from_struct(map_or_struct)
  def destruct(map_or_struct) when is_map(map_or_struct), do: map_or_struct

  @spec maybe_compute_nested_branches(branch_nested, opts_branch) :: branch_nested
  def maybe_compute_nested_branches(
        %Branch.Nested{} = branch_struct,
        %{branches: branches} = _branch_map
      ),
      do: Map.put(branch_struct, :branches, add_precomputed_values!(branches, branch_struct))

  def maybe_compute_nested_branches(%Branch.Nested{} = branch_struct, %{} = _branch_map),
    do: branch_struct

  @spec aggregate_attrs(branches, list(binary | atom), list) :: list
  def aggregate_attrs(branches, keys, acc \\ []) do
    branches
    |> Enum.reduce(acc, fn
      {_slug, %{attrs: attrs}}, acc ->
        [get_values(attrs, keys) | acc]
    end)
    |> List.flatten()
    |> Enum.uniq()
  end

  @spec get_values(map, list(binary | atom)) :: tuple
  defp get_values(attrs, keys),
    do: List.to_tuple(for(key <- keys, do: Map.get(attrs, key)))
end
