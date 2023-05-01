defmodule Routex.Extension.Alternatives.Scope.Nested do
  @moduledoc """
  Struct for scope with optionally nested scopes
  """
  @type t :: %__MODULE__{
          attrs: %{atom => any} | nil,
          scope_path: list(binary),
          scope_prefix: binary,
          scope_alias: atom,
          scopes: %{(binary | atom) => t} | nil
        }

  defstruct [
    :scope_alias,
    attrs: %{},
    scope_path: [],
    scope_prefix: "",
    scopes: %{}
  ]
end

defmodule Routex.Extension.Alternatives.Scope.Flat do
  @moduledoc """
  Struct for flattened scope
  """
  @type t :: %__MODULE__{
          attrs: %{atom => any} | nil,
          scope_path: list(binary),
          scope_prefix: binary,
          scope_alias: atom
        }

  defstruct [
    :scope_alias,
    attrs: %{},
    scope_path: [],
    scope_prefix: ""
  ]
end

defmodule Routex.Extension.Alternatives.Scopes do
  @moduledoc false

  alias Routex.Extension.Alternatives.Scope

  @type scopes :: %{(binary | nil) => Scope.Flat.t()}
  @type scopes_nested :: %{(binary | nil) => Scope.Nested.t()}
  @type scopes_nested_tuple :: {binary | nil, Scope.Nested.t()}
  @type scope_nested :: Scope.Nested.t()
  @type scope_tuple :: {binary | nil, Scope.Flat.t()}
  @type opts_scope :: Routex.opts_scope()

  # return a list of unique values attr to given key. Returns a list
  # of tuples with unique combinations when a list of keys is given.
  @spec attr_values(scopes, atom | binary) :: list(any)
  def attr_values(scopes, key) when is_atom(key) or is_binary(key),
    do: scopes |> attr_values([key]) |> Stream.map(&elem(&1, 0)) |> Enum.uniq()

  @spec attr_values(scopes, list(atom | binary)) :: list({atom | binary, any})
  def attr_values(scopes, keys) when is_list(keys) do
    scopes |> aggregate_attrss(keys) |> Enum.uniq()
  end

  # takes a nested map of maps and returns a flat map with concatenated keys, aliases and prefixes.
  @spec flatten(scopes :: scopes_nested) :: scopes()
  def flatten(scopes), do: scopes |> do_flatten_scopes() |> List.flatten() |> Map.new()

  @spec do_flatten_scopes(scopes_nested, nil | {binary, any} | {nil, nil}) ::
          list(scopes)
  def do_flatten_scopes(scopes, parent \\ {nil, nil}) do
    Enum.reduce(scopes, [], fn
      {_, scope_opts} = full_scope, acc ->
        new_scope = flatten_scope(full_scope, parent)
        flattened_subtree = do_flatten_scopes(scope_opts.scopes, new_scope)

        [[new_scope | flattened_subtree] | acc]
    end)
  end

  @spec flatten_scope(scopes_nested_tuple(), scope_tuple) :: scope_tuple
  def flatten_scope({_scope, scope_opts}, {_p_scope, p_scope_opts})
      when is_nil(p_scope_opts) or is_nil(p_scope_opts.scope_alias) do
    scope_opts = Map.drop(scope_opts, [:scopes])
    scope_key = scope_opts.attrs.scope_helper
    {scope_key, struct(Scope.Flat, Map.from_struct(scope_opts))}
  end

  def flatten_scope({_scope, scope_opts}, {_p_scope, p_scope_opts}) do
    flattened_scope_prefix = Path.join(p_scope_opts.scope_prefix, scope_opts.scope_prefix)

    flattened_scope_alias =
      String.to_atom(
        "#{Atom.to_string(p_scope_opts.scope_alias)}_#{Atom.to_string(scope_opts.scope_alias)}"
      )

    scope_opts = %{
      scope_opts
      | scope_prefix: flattened_scope_prefix,
        scope_alias: flattened_scope_alias
    }

    new_scope_opts = Map.drop(scope_opts, [:scopes])
    new_scope_key = scope_opts.attrs.scope_helper

    {new_scope_key, struct(Scope.Flat, Map.from_struct(new_scope_opts))}
  end

  @spec get_slug_key(binary) :: binary
  def get_slug_key(slug), do: slug |> String.replace("/", "_") |> String.replace_prefix("_", "")

  @spec get_scope_opts(slug :: binary, list(binary)) :: %{
          key: nil | binary,
          path: list,
          prefix: binary,
          alias: nil | atom,
          helper: nil | binary
        }
  def get_scope_opts("/", []) do
    %{key: nil, path: [], prefix: "", alias: nil, helper: nil}
  end

  def get_scope_opts(slug, p_scope_path) when is_list(p_scope_path) do
    key = get_slug_key(slug)
    path = Enum.concat(p_scope_path, [key])

    %{
      key: key,
      path: path,
      prefix: key,
      alias: String.to_atom(key),
      helper: Enum.join(path, "_")
    }
  end

  @spec add_precomputed_values!(%{binary => opts_scope}, parent_scope :: scope_nested) ::
          scopes_nested
  def add_precomputed_values!(scopes, p_scope \\ %Scope.Nested{}) do
    for {slug, scope} <- scopes, into: %{} do
      scope = Map.put_new(scope, :attrs, Map.new())
      scope_opts = get_scope_opts(slug, p_scope.scope_path)
      attrs_map = destruct(scope.attrs)

      new_attrs =
        p_scope.attrs
        |> Map.merge(attrs_map)
        |> Map.put(:scope_helper, scope_opts.helper)

      new_opts =
        maybe_compute_nested_scopes(
          %Scope.Nested{
            attrs: new_attrs,
            scope_path: scope_opts.path,
            scope_prefix: Path.join("/", scope_opts.prefix),
            scope_alias: scope_opts.alias
          },
          scope
        )

      {scope_opts.key, new_opts}
    end
  end

  @spec destruct(map | struct) :: map
  def destruct(map_or_struct) when is_struct(map_or_struct), do: Map.from_struct(map_or_struct)
  def destruct(map_or_struct) when is_map(map_or_struct), do: map_or_struct

  @spec maybe_compute_nested_scopes(scope_nested, opts_scope) :: scope_nested
  def maybe_compute_nested_scopes(
        %Scope.Nested{} = scope_struct,
        %{scopes: scopes} = _scope_map
      ),
      do: Map.put(scope_struct, :scopes, add_precomputed_values!(scopes, scope_struct))

  def maybe_compute_nested_scopes(%Scope.Nested{} = scope_struct, %{} = _scope_map),
    do: scope_struct

  @spec aggregate_attrss(scopes, list(binary | atom), list) :: list
  def aggregate_attrss(scopes, keys, acc \\ []) do
    scopes
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
