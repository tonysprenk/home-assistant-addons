# Direct AirPlay ALSA

Direct AirPlay ALSA turns a Raspberry Pi running Home Assistant OS into an AirPlay 2 receiver and sends audio directly to the Raspberry Pi headphone output.

This add-on bypasses Home Assistant OS Audio and PulseAudio. It maps `/dev/snd` into the add-on container, renders an ALSA-only Shairport Sync configuration, and prints ALSA diagnostics every time it starts.

Default settings target the Raspberry Pi 3.5 mm jack:

- AirPlay name: `De Kleine Eekhoorn`
- ALSA device: `plughw:0,0`
- Mixer: `Headphone`
- Startup mixer volume: `85`
