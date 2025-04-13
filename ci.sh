#!/bin/bash
set -e

[ "$GITHUB_ACTIONS" != "true" ] && mix format

mix deps.unlock --unused
mix compile --warnings-as-errors --force
mix compile --warnings-as-errors
mix format --check-formatted
mix credo --strict
mix dialyzer
mix test
mix docs

if [ "$GITHUB_ACTIONS" = "true" ]; then
  mix coveralls.github
else
  mix coveralls.html
fi
