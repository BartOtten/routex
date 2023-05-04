#!/bin/bash
set -e

mix compile --warnings-as-errors --force
mix compile --warnings-as-errors
mix credo --strict
mix test
mix docs
