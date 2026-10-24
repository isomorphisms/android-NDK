#!/usr/bin/env bash
# Compatibility entry for existing callers; the owned verifier is Grease.
exec "${ANDROID_GREASE:?ANDROID_GREASE must name the verified Grease runtime}" \
    "$(dirname -- "$0")/verify-nativeactivity-receipt.grease" "$@"
