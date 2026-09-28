#!/bin/bash
set -Eeuo pipefail
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
mkdir /var/run/suricata/unraid-ids-update.lock 2>/dev/null || exit 0
trap 'rmdir /var/run/suricata/unraid-ids-update.lock' EXIT
echo "[$(date -Is)] Updating Suricata rules"
suricata-update --no-reload
if [[ -r /var/run/suricata/suricata.pid ]]; then
  read -r sensor_pid < /var/run/suricata/suricata.pid
  [[ "$sensor_pid" =~ ^[0-9]+$ ]] || exit 1
  kill -USR2 "$sensor_pid"
  echo 'Requested live rule reload. Check suricata.log for the result.'
fi
