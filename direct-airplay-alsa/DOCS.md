# Direct AirPlay ALSA Documentation

## Install

1. Stop the existing Airplay 2 for Home Assistant add-on.
2. Add this repository to the Home Assistant add-on store, or copy `direct-airplay-alsa` into the local add-ons folder.
3. Reload the add-on store.
4. Install Direct AirPlay ALSA.
5. Keep the default options for Home Assistant Audio.
6. Start the add-on.

## Test

Open the add-on logs and confirm these lines appear:

```text
Direct AirPlay ALSA startup
$ shairport-sync -V
ALSA output probe completed successfully
$ shairport-sync --displayConfig
Starting Shairport Sync
```

Select De Kleine Eekhoorn from Apple Music and start playback.

When playback begins, the logs should include:

```text
shairport-sync session event: play-begins
```

When playback stops, the logs should include:

```text
shairport-sync session event: play-ends
```

## Troubleshooting

If the add-on exits with `Selected ALSA output device pulse could not be opened`, inspect the `pactl info`, `pactl list short sinks`, and `aplay -L` output printed above the error. Home Assistant Audio must expose a working PulseAudio server to the add-on.

If the add-on warns that a mixer control was not found, leave `mixer_name` empty. Home Assistant Audio owns the physical mixer and Shairport Sync will use software volume.

If AirPlay discovery works but audio is silent, change `log_level` to `debug`, restart the add-on, start playback, and inspect the logs for `play-begins`, ALSA open errors, or Shairport Sync session errors.

If Apple Home keeps showing stale `No Response` state after upgrading, leave `airplay_device_id` empty for the first test. If the issue remains, configure a fixed 12-16 digit hexadecimal ID and re-add the speaker to Apple Home so HomeKit sees a stable receiver identity.

## Rollback

1. Stop Direct AirPlay ALSA.
2. Start the existing Airplay 2 for Home Assistant add-on.
3. Select the original AirPlay speaker from Apple Music.

## Remote Home Assistant Runtime Checklist

Before starting this add-on, stop the existing `Airplay 2 for Home Assistant` add-on so only one AirPlay receiver advertises `De Kleine Eekhoorn`.

Use these default options first:

```yaml
airplay_name: De Kleine Eekhoorn
alsa_device: pulse
mixer_name: ""
mixer_volume: 85
log_level: info
interpolation: auto
default_airplay_volume: "-12.0"
use_precision_timing: "no"
disable_standby_mode: always
statistics: "no"
airplay_device_id: ""
```

Expected startup evidence:

```text
Direct AirPlay ALSA startup
$ aplay -l
$ aplay -L
$ pactl list short sinks
ALSA output probe completed successfully
$ shairport-sync --displayConfig
Starting Shairport Sync
```

Expected playback evidence:

```text
shairport-sync session event: play-begins
```

If playback stutters, test `interpolation: vernier` first. If playback is silent, change `log_level` to `debug`, restart, and capture the full log from add-on startup through one Apple Music play attempt.
