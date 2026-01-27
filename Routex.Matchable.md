# `Routex.Matchable`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/matchable.ex#L1)

Matchables are an essential part of Routex. They are used to match run time
routes with compile time routes and enable reordered route segments.

This module provides functions to create Matchables, convert them to match
pattern AST as well as function head AST, and check if the routing values
of two Matchable records match.

# `multi`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/matchable.ex#L26)

```elixir
@type multi() :: binary() | map() | list() | Routex.Types.ast() | Routex.Types.route()
```

# `t`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/matchable.ex#L17)

```elixir
@type t() ::
  {:matchable, hosts :: list(), path :: list(), trailing_slash :: list(),
   query :: list(), fragment :: list()}
```

# `is_matchable`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/matchable.ex#L42)
*macro* 

Returns true if `term` is a Matchable record

# `match?`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/matchable.ex#L362)

```elixir
@spec match?(multi() | t(), multi() | t()) :: boolean()
```

Returns whether two Matchable records match on their route defining
properties. The first argument supports param en wildcard syntax
(e.g ":param" and "*").

## Example

    iex> route_record = %Phoenix.Router.Route{path: "/posts/:id"} |> Routex.Matchable.new()
    iex> matching_record = "/posts/1/foo=bar#top" |> Routex.Matchable.new()
    iex> non_matching_record = "/other/1/foo=bar#op" |> Routex.Matchable.new()

    iex> match?(route_record, matching_record)
    true

    iex match?(route_record, non_matching_record)
    false

# `matchable`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/matchable.ex#L31)
*macro* 

# `matchable`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/matchable.ex#L31)
*macro* 

# `new`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/matchable.ex#L64)

```elixir
@spec new(input :: multi()) :: t()
```

Converts a binary URL, `Phoenix.Router.Route` or (sigil) AST argument into a Matchable record.

## Examples

  iex> path = "/posts/1?foo=bar#top"
  iex> route = %Phoenix.Router.Route{path: "/posts/:id"}
  iex> ast = {:<<>>, [], ["/products/", {:"::", [], [{{:., [], [Kernel, :to_string]}, [from_interpolation: true], [{:id, [], Elixir}]}, {:binary, [], Elixir}]}]}

	iex> path_match = Routex.Matchable.new(path)
	{:matchable, [nil], ["posts", "1"], "foo=bar", "top", false}

	iex> route_match = Routex.Matchable.new(route)
	{:matchable, [], ["posts", ":id"], nil, nil, false}

	iex> ast_match = Routex.Matchable.new(ast)
	{:matchable, [], ["posts", {:"::", [], [{{:., [], [Kernel, :to_string]}, [from_interpolation: true], [{:id, [], Elixir}]}, {:binary, [], Elixir}]}], nil, nil, false}

# `to_ast_segments`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/matchable.ex#L329)

```elixir
@spec to_ast_segments(t()) :: [Routex.Types.ast()]
```

Takes a record and returns a list of ast, each element matching one segment.

# `to_func`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/matchable.ex#L228)

```elixir
@spec to_func(pattern :: t(), name :: atom(), args :: keyword(), Routex.Types.ast()) ::
  Routex.Types.ast()
```

Creates a function named `name` which the first argument matching
a Matchable record pattern. Other arguments can be given with either a
catch all or a pattern.

The Matchable pattern is bound to variable `pattern`

## Example
    iex> "/some/path"
       >  |> Matchable.new()
       >  |> Matchable.to_func(:my_func, [pattern_arg: "fixed", :catchall_arg], quote(do: :ok))

# `to_pattern`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/matchable.ex#L282)

Returns a match pattern for given `Matchable` record or `Phoenix.Router.Route`.
The pattern can be used either as function argument or in a function body. As
the pattern binds values, the bindings can be used to convert input from one
pattern to another.

## Examples
  iex> "/original/:arg1/:arg2" |> Routex.Matchable.new() |> Routex.Matchable.to_pattern()
	{:{}, [], [:matchable, {:hosts, [], Routex.Matchable}, ["original", {:arg1, [], Routex.Matchable}, {:arg2, [], Routex.Matchable}], {:query, [], Routex.Matchable}, {:fragment, [], Routex.Matchable}, false]}

	iex> "/recomposed/:arg2/:arg1" |> Routex.Matchable.new() |> Routex.Matchable.to_pattern()
	{:{}, [], [:matchable, {:hosts, [], Routex.Matchable}, ["recomposed", {:arg2, [], Routex.Matchable}, {:arg1, [], Routex.Matchable}], {:query, [], Routex.Matchable}, {:fragment, [], Routex.Matchable}, false]}

	iex> "/original/segment_1/segment_2" |> Routex.Matchable.new() |> Routex.Matchable.to_pattern()
	{:{}, [], [:matchable, {:hosts, [], Routex.Matchable}, ["original", "segment_1", "segment_2"], {:query, [], Routex.Matchable}, {:fragment, [], Routex.Matchable}, false]}

---

*Consult [api-reference.md](api-reference.md) for complete listing*
