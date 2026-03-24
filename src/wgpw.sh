#!/bin/sh
# Wrapper for host runtime usage
set -e
# proxy command
bun "$(cd "$(dirname "$0")" && pwd)/wgpw.mjs" "$@"