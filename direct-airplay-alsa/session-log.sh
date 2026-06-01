#!/bin/sh
set -eu

event="${1:-unknown}"
printf 'shairport-sync session event: %s\n' "$event" >&2
