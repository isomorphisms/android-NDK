#!/bin/sh
# Compatibility entrypoint only; no Bash packaging fallback.
exec grease "$(dirname "$0")/run-packager.ysh" "$@"
