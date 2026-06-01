FROM mikebrady/shairport-sync:4.3.7

RUN apk add --no-cache \
    alsa-plugins-pulse \
    alsa-utils \
    envsubst \
    jq \
    pulseaudio-utils

COPY run.sh /run.sh
COPY session-log.sh /usr/local/bin/session-log.sh
COPY shairport-sync.conf.tpl /etc/shairport-sync.conf.tpl

RUN chmod +x /run.sh /usr/local/bin/session-log.sh

ENTRYPOINT ["/run.sh"]
