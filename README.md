# Suricata and EveBox templates for Unraid

Source repository: `almapavi/suricata-docker`.

This source builds `ghcr.io/almapavi/suricata-unraid:latest`: a Suricata image with initialization, ET Open rule updates and log rotation embedded in the image. EveBox provides a separate web interface for reviewing the sensor’s events and alerts.

Replace `my-application-I-want-to-monitor` with the exact name of the running container you want to monitor. The existing template names, **Suricata-Proxy-IDS** and **EveBox-Proxy-IDS**, also support monitoring other containers.

### Download and load the templates

1. On the repository's **Code** page, select **Code > Download ZIP** and extract the archive. Open its `templates` folder. Alternatively, open each XML file on GitHub and use **Download raw file**.
2. Copy **Suricata-Proxy-IDS.xml** and **EveBox-Proxy-IDS.xml** to `/boot/config/plugins/dockerMan/templates-user/` using a file manager or SFTP. Replace older copies with the same filenames.
3. Go to **Docker > Add Container** and select **Suricata-Proxy-IDS**. The name, repository, overview, appdata paths and capture settings should populate automatically.

### Configure Suricata

Start the container you want to monitor before configuring the sensor. Use these settings in the Unraid form:

Unraid shows **Network Type** and **Container Network** as separate fields. In the XML, this selection is represented as `container:my-application-I-want-to-monitor`. The `container:` prefix is network syntax, not part of the container's name. Replace the template's default container selection with your own.

Suricata shares the monitored container's network interfaces and IP address. No separate IP address or additional network is required. Other capture setups require an interface that receives the intended traffic; promiscuous mode alone does not make all network traffic visible.

The following settings appear directly on the form:

| Field | Default | What to configure |
|---|---|---|
| **Configuration** | `/mnt/user/appdata/suricata-proxy/config` | Persistent Suricata configuration. |
| **Detection rules and cache** | `/mnt/user/appdata/suricata-proxy/data` | Persistent detection rules and cache. |
| **Event logs** | `/mnt/user/appdata/suricata-proxy/logs` | Persistent events and logs; EveBox must read this same host directory. |
| **Capture interface** | `eth0` | The interface carrying the traffic to inspect inside the monitored container. |
| **Protected networks** | `[192.168.0.0/16,10.0.0.0/8,172.16.0.0/12]` | Set your protected CIDRs as a bracketed, comma-separated list. Supplies `HOME_NET`. |
| **External networks** | `any` | Supplies `EXTERNAL_NET`. Includes internal sources, which is useful when monitoring forwarded traffic. Adjust to suit your detection requirements. |
| **HTTP backend ports** | A prefilled list of common HTTP service ports | Include the actual HTTP service ports you want to inspect. Supplies `HTTP_PORTS`. |
| **Update rules at startup** | `yes` | Update rules when the sensor starts. Missing rules are downloaded even when set to `no`. |
| **Daily rule updates** | `yes` | Schedule rule updates for 04:17 in the container timezone. |
| **Rotate each log at MB** | `256` | Rotation threshold per log, checked every five minutes. |
| **Rotated copies per log** | `7` | Number of uncompressed rotated copies to retain per log. |
| **Timezone** | `Etc/UTC` | Set the timezone for scheduled updates. |

If you are replacing an existing installation, use its existing appdata paths to retain configuration, rules and logs.

Click **Apply**. Unraid downloads the published image; first startup prepares missing configuration, downloads rules and validates the sensor configuration. No runtime script directory or image build is needed on Unraid.

### Configure EveBox

1. Go to **Docker > Add Container** and select **EveBox-Proxy-IDS**.
2. Confirm **Repository** is `jasonish/evebox:latest`.
3. Set **Suricata event logs** to the same host directory as Suricata's **Event logs**. The default is `/mnt/user/appdata/suricata-proxy/logs`. EveBox mounts it read-only.
4. Keep **EveBox data** at `/mnt/user/appdata/evebox-proxy` or choose another persistent location.
5. Choose EveBox's network. The template defaults to **Bridge**, publishing TCP 5636 on the Unraid host. You may instead select a custom VLAN and an unused fixed container IP; access EveBox using that IP on TCP 5636. EveBox has its own network configuration and does not need to share the monitored container's network namespace.
6. Click **Apply**, then open EveBox's Docker **Logs** for the generated admin password. Open **WebUI**. TLS and authentication remain enabled; the initial certificate is self-signed.

The default search time range is `24h`. **Persistent login and TLS configuration**, under **Show more settings**, points to `/var/lib/evebox` inside the container so credentials and certificates remain in the persistent data directory.

### Verify traffic and alerts

Generate traffic to or from the monitored container and confirm corresponding events appear in EveBox. For an HTTP service, make an unencrypted HTTP request and check for an HTTP event. Confirm a harmless test request triggers a known enabled detection rule before relying on alerts. Ordinary traffic does not necessarily trigger an alert.

EveBox is an event and alert GUI, not a full Suricata rule editor.

When monitoring `my-application-I-want-to-monitor`, start that container before the sensor. If the monitored container is recreated during an update, recreate the sensor from its saved template to reconnect it to the new network namespace. Preserve the sensor's appdata. Automatic Docker dependency management and Docker socket access are not included.

## Icons

Use **Edit > Advanced View > Icon URL** in Unraid to assign a direct HTTPS static image URL for each container. The Icon fields are intentionally empty until artwork is chosen. If a particular Unraid release does not expose the field, edit `<Icon>` in its saved XML and load that template again. Use a raw image URL, not an HTML file-view link.

## Settings and maintenance

- The template variables `IDS_HOME_NET`, `IDS_EXTERNAL_NET` and `IDS_HTTP_PORTS` set Suricata’s `HOME_NET`, `EXTERNAL_NET` and `HTTP_PORTS` values at startup. The original YAML is backed up as `suricata.yaml.before-unraid-template`; unrelated content and comments remain.
- Daily ET Open updates default to 04:17 in the container timezone and request a live reload. Check `maintenance.log` and `suricata.log` for results. The default public timezone is UTC.
- Raw logs rotate at 256 MB per file with seven uncompressed rotated copies, checked every five minutes. This is not a hard disk quota. EveBox defaults to seven-day SQLite event retention, separate from raw logs.
- Persistent configuration, rules and event paths are editable in the templates. Preserve them when containers are recreated.
- This sensor is passive IDS. It does not block traffic, decrypt encrypted application traffic, configure email notifications or integrate with an external Elasticsearch cluster automatically.
- `HTTP_PORTS` affects signatures that restrict inspection by port. Include the actual HTTP service ports used by `my-application-I-want-to-monitor`, even when HTTP is already being decoded.
- Sharing `my-application-I-want-to-monitor`’s network namespace provides access to its network interfaces. It does not automatically expose traffic belonging to other containers or the entire VLAN.
- The upstream default worker count is retained. Check resource use and packet-loss counters on the actual Unraid host and tune as needed.
- The first build uses the upstream `jasonish/suricata:8.0` patch stream. Select a tested exact tag or digest for a reproducible release. Base image updates require rerunning the publish workflow, then updating or recreating the sensor in Unraid.

## Community Applications

These templates are for manual installation until accepted into Community Applications. Test fresh setup, appdata reuse, icon changes, live traffic detection, scheduled updates, log rotation and sensor recreation on Unraid before requesting a listing. Verify the support URL and choose static icons you have permission to distribute. Choose a license for the authored helper code and retain upstream notices when distributing images.

Community Applications generally restricts duplicate listings using an already-listed container repository. The EveBox template uses its upstream image; check for an existing listing and consider contributing changes there. A custom sensor image does not guarantee acceptance.

[Community Applications policies](https://forums.unraid.net/topic/87144-ca-application-policies-privacy-policy/)

## Validation

Local checks cover source syntax, template structure, matching log mounts and invalid-setting rejection. The workflow adds real Docker build checks and a network-isolated image check for upstream initialization, embedded files, configuration parsing and idempotent configuration updates.

These checks do not replace a live capture and alert test using traffic from `my-application-I-want-to-monitor` on Unraid.

## References

- https://github.com/jasonish/docker-suricata
- https://evebox.org/docs/server/
- https://docs.github.com/en/actions/tutorials/publish-packages/publish-docker-images
- https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry
- https://docs.suricata.io/en/suricata-8.0.6/output/log-rotation.html
- https://docs.suricata.io/en/suricata-8.0.6/rule-management/rule-reload.html
