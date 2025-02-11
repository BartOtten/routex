# A comparison of regex in `Routex.Matchable.new/1` to the regex in
# `URI.parse/1` using a binary URL. Routex supports interpolation syntax but the
# benchmark is without due to missing support in URI.

uri = "https://user@foo.com:80/bar/product?q=baz#top"
regex_native = ~r{^(([a-z][a-z0-9\+\-\.]*):)?(//([^/?#]*))?([^?#]*)(\?([^#]*))?(#(.*))?}i
regex_rtx = ~r"^(?:(?P<scheme>[a-z][a-z0-9+\-.]*):)?(?P<authority>(?:\/\/)?[^/?#]*)(?P<path>(?:(?:\/(?:[^/?#]+|#\{[^}]+\}))+)?)(?P<trailing_slash>\/?)(?P<query>\?[^#]*)?(?P<fragment>#[^#]*)?$"

Benchee.run(
  %{
    "native" => fn -> Regex.run(regex_native, uri) end,
    "rtx" => fn -> Regex.run(regex_rtx, uri) end
  },
  warmup: 10,
  time: 20,
  memory_time: 5
)

# Name             ips        average  deviation         median         99th %
# native      509.87 K        1.96 μs  ±2576.29%        1.75 μs        2.79 μs
# rtx         440.51 K        2.27 μs  ±1953.10%        2.04 μs        2.38 μs

# Comparison:
# native      509.87 K
# rtx         440.51 K - 1.16x slower +0.31 μs

# Memory usage statistics:

# Name      Memory usage
# native           640 B
# rtx              504 B - 0.79x memory usage -136 B
