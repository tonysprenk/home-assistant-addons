general =
{
  name = "${AIRPLAY_NAME}";
  interpolation = "${INTERPOLATION}";
  output_backend = "alsa";
  default_airplay_volume = ${DEFAULT_AIRPLAY_VOLUME};
  drift_tolerance_in_seconds = 0.002;
  resync_threshold_in_seconds = 0.050;
};

sessioncontrol =
{
  run_this_before_play_begins = "/usr/local/bin/session-log.sh play-begins";
  run_this_after_play_ends = "/usr/local/bin/session-log.sh play-ends";
  wait_for_completion = "no";
  allow_session_interruption = "yes";
  session_timeout = 60;
};

alsa =
{
  output_device = "${ALSA_DEVICE}";
${MIXER_CONFIG_LINE}
  mixer_device = "default";
  output_rate = "auto";
  output_format = "auto";
  use_precision_timing = "${USE_PRECISION_TIMING}";
  disable_standby_mode = "${DISABLE_STANDBY_MODE}";
};

diagnostics =
{
  log_verbosity = ${LOG_VERBOSITY_NUM};
  log_output_to = "stderr";
  statistics = "yes";
};
