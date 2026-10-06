#!/bin/sh
# Compatibility entrypoint only; maintained implementation executes in Grease.
exec grease "$(dirname "$0")/build-nativeactivity-apk.ysh" "$@"
