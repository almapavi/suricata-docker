#!/bin/bash
# Runs through the inherited entrypoint, without network or host appdata mounts.
set -Eeuo pipefail
test -s /etc/suricata/suricata.yaml
for tool in python3 suricata suricata-update crond logrotate; do command -v "$tool"; done
for file in start-suricata.sh update-rules.sh validate-settings.py configure-sensor.py; do
    test -r "/opt/unraid-ids/$file"
done
export CAPTURE_INTERFACE=eth0
export IDS_HOME_NET='[10.0.0.0/8]'
export IDS_EXTERNAL_NET=any
export IDS_HTTP_PORTS='[80,8080,8989]'
python3 /opt/unraid-ids/validate-settings.py
python3 /opt/unraid-ids/configure-sensor.py /etc/suricata/suricata.yaml
python3 /tests/check-config.py
suricata -V
suricata --dump-config >/tmp/config-dump.txt
grep -F '10.0.0.0/8' /tmp/config-dump.txt
echo 'Embedded helpers, upstream initialization and configuration parsing passed.'
