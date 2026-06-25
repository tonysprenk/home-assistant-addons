#!/usr/bin/with-contenv bashio
set -euo pipefail

file="/config/known_devices.yaml"
backup="/config/known_devices.yaml.codex-backup-20260625"
tmp="$(mktemp)"

if [[ ! -f "$file" ]]; then
  bashio::log.warning "$file does not exist; nothing to clean."
  exit 0
fi

cp "$file" "$backup"

awk '
  /^[[:space:]]+consider_home:[[:space:]]*(None|null|~)[[:space:]]*$/ {
    removed++
    next
  }
  { print }
  END {
    if (removed > 0) {
      printf("removed=%d\n", removed) > "/tmp/known_devices_cleanup_result"
    } else {
      printf("removed=0\n") > "/tmp/known_devices_cleanup_result"
    }
  }
' "$backup" > "$tmp"

mv "$tmp" "$file"

result="$(cat /tmp/known_devices_cleanup_result)"
bashio::log.info "known_devices.yaml cleanup complete: ${result}; backup: ${backup}"
