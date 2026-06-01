#!/bin/sh
set -eu

CONFIG_PATH="/data/options.json"
TEMPLATE_PATH="/etc/shairport-sync.conf.tpl"
OUTPUT_PATH="/etc/shairport-sync.conf"
ALSA_PROBE_LOG="/tmp/alsa-open-check.log"
DBUS_LOG="/tmp/dbus.log"
AVAHI_LOG="/tmp/avahi.log"
NQPTP_LOG="/tmp/nqptp.log"

log() {
  printf '%s\n' "$*"
}

warn() {
  printf 'WARN: %s\n' "$*" >&2
}

fail() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "Missing required command: $1"
}

json_get() {
  key="$1"
  default="$2"
  jq -r --arg key "$key" --arg default "$default" '.[$key] // $default' "$CONFIG_PATH"
}

print_command() {
  log ""
  log "$ $*"
  "$@" 2>&1 || true
}

wait_for_command() {
  description="$1"
  attempts="$2"
  shift 2

  i=1
  while [ "$i" -le "$attempts" ]; do
    if "$@" >/dev/null 2>&1; then
      log "$description is ready"
      return 0
    fi
    sleep 1
    i=$((i + 1))
  done

  return 1
}

start_background_service() {
  name="$1"
  logfile="$2"
  shift 2

  log "Starting $name"
  "$@" >"$logfile" 2>&1 &
  pid="$!"
  sleep 1
  if ! kill -0 "$pid" >/dev/null 2>&1; then
    cat "$logfile" >&2 || true
    fail "$name exited during startup"
  fi
  log "$name started with pid $pid"
}

require_command "aplay"
require_command "amixer"
require_command "avahi-daemon"
require_command "dbus-daemon"
require_command "dbus-send"
require_command "envsubst"
require_command "jq"
require_command "shairport-sync"

[ -f "$CONFIG_PATH" ] || fail "$CONFIG_PATH is missing"
[ -f "$TEMPLATE_PATH" ] || fail "$TEMPLATE_PATH is missing"

AIRPLAY_NAME="$(json_get airplay_name "De Kleine Eekhoorn")"
ALSA_DEVICE="$(json_get alsa_device "pulse")"
MIXER_NAME="$(json_get mixer_name "")"
MIXER_VOLUME="$(json_get mixer_volume "85")"
LOG_LEVEL="$(json_get log_level "info")"
INTERPOLATION="$(json_get interpolation "auto")"
DEFAULT_AIRPLAY_VOLUME="$(json_get default_airplay_volume "-12.0")"
USE_PRECISION_TIMING="$(json_get use_precision_timing "no")"
DISABLE_STANDBY_MODE="$(json_get disable_standby_mode "always")"

case "$LOG_LEVEL" in
  debug) LOG_VERBOSITY_NUM="2" ;;
  info) LOG_VERBOSITY_NUM="0" ;;
  *) fail "Unsupported log_level: $LOG_LEVEL" ;;
esac

if [ -n "$MIXER_NAME" ]; then
  MIXER_CONFIG_LINE="  mixer_control_name = \"$MIXER_NAME\";"
else
  MIXER_CONFIG_LINE="  // mixer_control_name omitted; Shairport Sync software volume is used."
fi

export AIRPLAY_NAME
export ALSA_DEVICE
export MIXER_CONFIG_LINE
export LOG_VERBOSITY_NUM
export INTERPOLATION
export DEFAULT_AIRPLAY_VOLUME
export USE_PRECISION_TIMING
export DISABLE_STANDBY_MODE

log "Direct AirPlay ALSA startup"
log "airplay_name=$AIRPLAY_NAME"
log "alsa_device=$ALSA_DEVICE"
log "mixer_name=$MIXER_NAME"
log "mixer_volume=$MIXER_VOLUME"
log "log_level=$LOG_LEVEL"
log "interpolation=$INTERPOLATION"
log "default_airplay_volume=$DEFAULT_AIRPLAY_VOLUME"
log "use_precision_timing=$USE_PRECISION_TIMING"
log "disable_standby_mode=$DISABLE_STANDBY_MODE"
log "PULSE_SERVER=${PULSE_SERVER:-unset}"

if command -v pactl >/dev/null 2>&1; then
  print_command pactl info
  print_command pactl list short sinks
fi

if [ -d /run/audio ]; then
  print_command ls -la /run/audio
fi

if [ -e /dev/snd ]; then
  print_command ls -la /dev/snd
fi

if [ -f /proc/asound/cards ]; then
  print_command cat /proc/asound/cards
fi

print_command aplay -l
print_command aplay -L
print_command amixer scontrols

if [ -n "$MIXER_NAME" ]; then
  if amixer sget "$MIXER_NAME" >/tmp/mixer-before.log 2>&1; then
    log ""
    log "Selected mixer before changes:"
    cat /tmp/mixer-before.log
    amixer sset "$MIXER_NAME" unmute >/dev/null 2>&1 || warn "Could not unmute mixer $MIXER_NAME"
    amixer sset "$MIXER_NAME" "${MIXER_VOLUME}%" >/dev/null 2>&1 || warn "Could not set mixer $MIXER_NAME to ${MIXER_VOLUME}%"
    print_command amixer sget "$MIXER_NAME"
  else
    warn "Mixer control $MIXER_NAME was not found; continuing with Shairport Sync software volume"
  fi
fi

log ""
log "Probing ALSA output device $ALSA_DEVICE with one second of silence"
rm -f "$ALSA_PROBE_LOG"
set +e
aplay -D "$ALSA_DEVICE" -q -f S16_LE -c 2 -r 44100 -d 1 /dev/zero >"$ALSA_PROBE_LOG" 2>&1
probe_status="$?"
set -e

case "$probe_status" in
  0)
    log "ALSA output probe completed successfully"
    ;;
  *)
    cat "$ALSA_PROBE_LOG" >&2 || true
    fail "Selected ALSA output device $ALSA_DEVICE could not be opened"
    ;;
esac

log ""
log "Rendering $TEMPLATE_PATH to $OUTPUT_PATH"
envsubst < "$TEMPLATE_PATH" > "$OUTPUT_PATH"
log "Rendered Shairport Sync config:"
sed -n '1,160p' "$OUTPUT_PATH"

log ""
log "Starting runtime services"
mkdir -p /run/dbus /run/avahi-daemon
rm -f /run/dbus/pid /run/dbus/system_bus_socket /run/avahi-daemon/pid

ulimit -n 1048576 >/dev/null 2>&1 || warn "Could not raise open-file limit"

start_background_service "D-Bus" "$DBUS_LOG" dbus-daemon --system --nofork --nopidfile
wait_for_command "D-Bus" 10 dbus-send --system / org.freedesktop.DBus.Peer.Ping || {
  cat "$DBUS_LOG" >&2 || true
  fail "D-Bus did not become ready"
}

start_background_service "Avahi" "$AVAHI_LOG" avahi-daemon --no-chroot
wait_for_command "Avahi" 15 sh -c 'state="$(dbus-send --system --dest=org.freedesktop.Avahi --print-reply / org.freedesktop.Avahi.Server.GetState 2>/dev/null | awk "/int32/ {print \$2}")"; [ "$state" = "2" ]' || {
  cat "$AVAHI_LOG" >&2 || true
  fail "Avahi did not become ready"
}

if command -v nqptp >/dev/null 2>&1; then
  start_background_service "NQPTP" "$NQPTP_LOG" nqptp
else
  warn "nqptp is missing; AirPlay 2 timing may not work"
fi

log ""
log "Starting Shairport Sync"
exec shairport-sync -c "$OUTPUT_PATH"
