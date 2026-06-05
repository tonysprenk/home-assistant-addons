#!/bin/sh
set -eu

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
APP_DIR="$ROOT_DIR/direct-airplay-alsa"

assert_contains() {
  file="$1"
  expected="$2"
  if ! grep -Fq "$expected" "$file"; then
    printf 'Expected %s to contain: %s\n' "$file" "$expected" >&2
    exit 1
  fi
}

assert_contains "$APP_DIR/Dockerfile" "FROM mikebrady/shairport-sync:5.0.4"
assert_contains "$APP_DIR/config.yaml" 'version: "0.1.5"'
assert_contains "$APP_DIR/config.yaml" 'watchdog: "tcp://[HOST]:[PORT:7000]"'
assert_contains "$APP_DIR/config.yaml" 'statistics: "no"'
assert_contains "$APP_DIR/config.yaml" 'airplay_device_id: ""'
assert_contains "$APP_DIR/config.yaml" 'statistics: "list(no|yes)"'
assert_contains "$APP_DIR/config.yaml" 'airplay_device_id: "match(^([0-9A-Fa-f]{12,16})?$)"'
assert_contains "$APP_DIR/shairport-sync.conf.tpl" 'statistics = "${STATISTICS}";'
assert_contains "$APP_DIR/shairport-sync.conf.tpl" '${AIRPLAY_DEVICE_ID_CONFIG_LINE}'
assert_contains "$APP_DIR/run.sh" 'print_command shairport-sync -V'
assert_contains "$APP_DIR/run.sh" 'print_command shairport-sync --displayConfig'
assert_contains "$APP_DIR/run.sh" 'AIRPLAY_DEVICE_ID_CONFIG_LINE='
