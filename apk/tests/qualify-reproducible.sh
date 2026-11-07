#!/usr/bin/env bash
# Compatibility entry for existing callers; all owned qualification is Grease.
exec "${ANDROID_GREASE:?ANDROID_GREASE must name the verified Grease runtime}" \
    "$(dirname -- "$0")/reproducible.grease" "$@"
