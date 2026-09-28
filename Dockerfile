# Build with build-image.sh. Runtime does not mount or download helper scripts.
ARG BASE_IMAGE=jasonish/suricata:8.0
FROM ${BASE_IMAGE}
LABEL org.opencontainers.image.title="Suricata for Unraid" \
      org.opencontainers.image.description="Passive proxy IDS with integrated initialization and maintenance helpers" \
      org.opencontainers.image.version="0.3.0"
USER root
COPY scripts/start-suricata.sh scripts/update-rules.sh scripts/validate-settings.py scripts/configure-sensor.py /opt/unraid-ids/
# Fail at build time if the upstream image no longer supplies a required tool.
RUN command -v bash && command -v python3 && command -v suricata && \
    command -v suricata-update && command -v crond && command -v logrotate && \
    id suricata && test -d /etc/suricata.dist && \
    bash -n /opt/unraid-ids/start-suricata.sh && \
    bash -n /opt/unraid-ids/update-rules.sh && \
    python3 /opt/unraid-ids/validate-settings.py
# Inherit upstream ENTRYPOINT; it creates missing default configuration files.
CMD ["/bin/bash", "/opt/unraid-ids/start-suricata.sh"]
