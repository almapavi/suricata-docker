#!/bin/bash
# Called through the upstream image entrypoint, which initializes /etc/suricata.
set -Eeuo pipefail
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export CAPTURE_INTERFACE="${CAPTURE_INTERFACE:-eth0}"
export IDS_HOME_NET="${IDS_HOME_NET:-[192.168.0.0/16,10.0.0.0/8,172.16.0.0/12]}"
export IDS_EXTERNAL_NET="${IDS_EXTERNAL_NET:-any}"
export IDS_HTTP_PORTS="${IDS_HTTP_PORTS:-[80,81,3000,3579,5000,8000,8008,8080,8081,8096,8181,8787,8989,7878,9000,32400]}"
export UPDATE_RULES_ON_START="${UPDATE_RULES_ON_START:-yes}"
export DAILY_RULE_UPDATES="${DAILY_RULE_UPDATES:-yes}"
export ROTATE_SIZE_MB="${ROTATE_SIZE_MB:-256}"
export ROTATE_COUNT="${ROTATE_COUNT:-7}"

python3 /opt/unraid-ids/validate-settings.py
if [[ ! -e "/sys/class/net/$CAPTURE_INTERFACE" ]]; then
  echo "ERROR: capture interface $CAPTURE_INTERFACE does not exist in this network namespace." >&2
  exit 1
fi
if [[ ! -s /etc/suricata/suricata.yaml ]]; then
  echo 'ERROR: upstream initialization did not create suricata.yaml.' >&2
  exit 1
fi

python3 /opt/unraid-ids/configure-sensor.py /etc/suricata/suricata.yaml
mkdir -p /var/lib/suricata/rules /var/log/suricata /var/run/suricata
if [[ "$UPDATE_RULES_ON_START" == yes || ! -s /var/lib/suricata/rules/suricata.rules ]]; then
  if ! suricata-update --no-reload; then
    if [[ ! -s /var/lib/suricata/rules/suricata.rules ]]; then
      echo 'ERROR: initial rule download failed; refusing to start without rules.' >&2
      exit 1
    fi
    echo 'WARNING: update failed; validating and using the existing rules.' >&2
  fi
fi

touch /var/log/suricata/maintenance.log
chown -R suricata:suricata /etc/suricata /var/lib/suricata /var/log/suricata /var/run/suricata

args=( -c /etc/suricata/suricata.yaml --af-packet="$CAPTURE_INTERFACE"
  --init-errors-fatal --pidfile=/var/run/suricata/suricata.pid )
suricata -T "${args[@]}"

# One cron configuration owned by this package; recreated with each container.
cat > /etc/logrotate.d/unraid-ids <<EOF
/var/log/suricata/*.log /var/log/suricata/*.json {
    size ${ROTATE_SIZE_MB}M
    rotate $ROTATE_COUNT
    missingok
    notifempty
    nocompress
    su suricata suricata
    create 0640 suricata suricata
    sharedscripts
    postrotate
        if test -r /var/run/suricata/suricata.pid; then
            kill -HUP \$(cat /var/run/suricata/suricata.pid) 2>/dev/null || true
        fi
    endscript
}
EOF
cat > /etc/cron.d/unraid-ids <<'EOF'
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
*/5 * * * * root logrotate -s /var/lib/suricata/logrotate.status /etc/logrotate.d/unraid-ids >> /var/log/suricata/maintenance.log 2>&1
EOF
if [[ "$DAILY_RULE_UPDATES" == yes ]]; then
  cat >> /etc/cron.d/unraid-ids <<'EOF'
17 4 * * * root /bin/bash /opt/unraid-ids/update-rules.sh >> /var/log/suricata/maintenance.log 2>&1
EOF
fi
chmod 0644 /etc/cron.d/unraid-ids /etc/logrotate.d/unraid-ids
# A previous container stop may have interrupted the updater before its EXIT trap.
rmdir /var/run/suricata/unraid-ids-update.lock 2>/dev/null || true
crond
echo "Starting passive Suricata on $CAPTURE_INTERFACE; HOME_NET=$IDS_HOME_NET; EXTERNAL_NET=$IDS_EXTERNAL_NET"
exec suricata --user suricata --group suricata "${args[@]}"
