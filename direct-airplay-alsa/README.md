# Direct AirPlay ALSA

Direct AirPlay ALSA turns a Raspberry Pi running Home Assistant OS into an AirPlay 2 receiver and sends audio to the Raspberry Pi headphone output through Home Assistant Audio.

The add-on uses Home Assistant's supported PulseAudio bridge (`audio: true`) and the ALSA PulseAudio plugin. Shairport Sync still uses its ALSA backend, but Home Assistant OS owns the physical sound card.

Default settings target the Raspberry Pi 3.5 mm jack:

- AirPlay name: `De Kleine Eekhoorn`
- ALSA device: `pulse`
- Mixer: disabled
- Startup mixer volume: managed by Home Assistant Audio
