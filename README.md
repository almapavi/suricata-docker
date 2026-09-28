# Suricata and EveBox templates for Unraid

Source repository: `almapavi/suricata-docker`.

This source builds `ghcr.io/almapavi/suricata-unraid:latest`: a Suricata image with initialization, ET Open rule updates and log rotation embedded in the image. EveBox provides a separate web interface for reviewing the sensor’s events and alerts.

The examples below use a fictional container named `container:my-application-I-want-to-monitor`. Replace it with the exact name of the container you want to monitor. The existing template names, **Suricata-Proxy-IDS** and **EveBox-Proxy-IDS**, also support monitoring other containers.

**Installation readiness:** use the registry-backed template only after the publish workflow succeeds and the container package is public. A passing build does not replace a live capture and alert test on Unraid.

## Install on Unraid after publication

1. Copy the two XML files in `templates/` to `/boot/config/plugins/dockerMan/templates-user/`, using a file manager or SFTP.
2. Go to **Docker > Add Container** and select **Suricata-Proxy-IDS**. Confirm the **Repository** field is set to `ghcr.io/almapavi/suricata-unraid:latest`. Under **Network Type**, select `container:my-application-I-want-to-monitor`, replacing `my-application-I-want-to-monitor` with the exact name of the running container you want to monitor. This shares that container’s network namespace with the sensor.
3. Set **Capture interface** to the interface inside the monitored container, usually `eth0`. Configure your protected networks using CIDR notation and include the HTTP service ports you want to inspect. The template’s **HTTP backend ports** field supplies Suricata’s `HTTP_PORTS` setting. **External networks** defaults to `any`, allowing rules to match traffic originating from internal addresses as well as external ones. Adjust it to suit your detection requirements.
4. Click **Apply**. Unraid downloads the published image; first startup prepares missing configuration, downloads rules and validates the sensor configuration. No runtime script directory or image build is needed on Unraid.
5. Add **EveBox-Proxy-IDS** and confirm its **Repository** field is set to `jasonish/evebox:latest`. Its Suricata log host path must match the sensor’s log host path. The template defaults to bridge networking with TCP 5636 published on the Unraid host. You may select your own custom VLAN and a free fixed container IP instead; on a custom VLAN, use that IP on TCP 5636. Click **Apply**.
6. Open EveBox’s Docker **Logs** for the generated admin password, then open **WebUI**. TLS and authentication remain enabled. The initial certificate is self-signed.
7. Generate traffic to or from the monitored container and confirm corresponding events appear in EveBox. For an HTTP service, make an unencrypted HTTP request and check for an HTTP event. Confirm a harmless test request triggers a known enabled detection rule before relying on alerts. EveBox is an event and alert GUI, not a full Suricata rule editor.

| Field                         | Value |
| **Network Type**              | **Container** |
| **Additional Networks**       | Leave empty/none |
| **Container Network**         | Select the running container you want to monitor, such as `my-application-I-want-to-monitor` |
| **Capture interface**         | The monitored container’s network interface, usually `eth0`, under **Show more settings** |

Suricata shares the monitored container’s network interfaces and IP address. No separate IP address or additional network is required.

When monitoring another container, such as `container:my-application-I-want-to-monitor`, start that container before the sensor. If the monitored container is recreated during an update, recreate the sensor from its saved template to reconnect it to the new network namespace. Preserve the sensor’s appdata. Automatic Docker dependency management and Docker socket access are not included.

## Icons

Use **Edit > Advanced View > Icon URL** in Unraid to assign a direct HTTPS static image URL for each container. The Icon fields are intentionally empty until artwork is chosen. If a particular Unraid release does not expose the field, edit `<Icon>` in its saved XML and load that template again. Use a raw image URL, not an HTML file-view link.

## Settings and maintenance

- The template’s `HOME_NET`, `EXTERNAL_NET` and `HTTP_PORTS` settings are applied at startup. The original YAML is backed up as `suricata.yaml.before-unraid-template`; unrelated content and comments remain.
- Daily ET Open updates default to 04:17 in the container timezone and request a live reload. Check `maintenance.log` and `suricata.log` for results. The default public timezone is UTC.
- Raw logs rotate at 256 MB per file with seven uncompressed rotated copies, checked every five minutes. This is not a hard disk quota. EveBox defaults to seven-day SQLite event retention, separate from raw logs.
- Persistent configuration, rules and event paths are editable in the templates. Preserve them when containers are recreated.
- This sensor is passive IDS. It does not block traffic, decrypt encrypted application traffic, configure email notifications or integrate with an external Elasticsearch cluster automatically.
- `HTTP_PORTS` affects signatures that restrict inspection by port. Include the actual HTTP service ports used by `container:my-application-I-want-to-monitor`, even when HTTP is already being decoded.
- Sharing `container:my-application-I-want-to-monitor`’s network namespace provides access to its network interfaces. It does not automatically expose traffic belonging to other containers or the entire VLAN.
- The upstream default worker count is retained. Check resource use and packet-loss counters on the actual Unraid host and tune as needed.
- The first build uses the upstream `jasonish/suricata:8.0` patch stream. Select a tested exact tag or digest for a reproducible release. Base image updates require rerunning the publish workflow, then updating or recreating the sensor in Unraid.

## Community Applications

These templates are for manual installation until accepted into Community Applications. Test fresh setup, appdata reuse, icon changes, live traffic detection, scheduled updates, log rotation and sensor recreation on Unraid before requesting a listing. Verify the support URL and choose static icons you have permission to distribute. Choose a license for the authored helper code and retain upstream notices when distributing images.

Community Applications generally restricts duplicate listings using an already-listed container repository. The EveBox template uses its upstream image; check for an existing listing and consider contributing changes there. A custom sensor image does not guarantee acceptance.

[Community Applications policies](https://forums.unraid.net/topic/87144-ca-application-policies-privacy-policy/)

## Validation

Local checks cover source syntax, template structure, matching log mounts and invalid-setting rejection. The workflow adds real Docker build checks and a network-isolated image check for upstream initialization, embedded files, configuration parsing and idempotent configuration updates.

These checks do not replace a live capture and alert test using traffic from `container:my-application-I-want-to-monitor` on Unraid.

## References

- https://github.com/jasonish/docker-suricata
- https://evebox.org/docs/server/
- https://docs.github.com/en/actions/tutorials/publish-packages/publish-docker-images
- https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry
- https://docs.suricata.io/en/suricata-8.0.6/output/log-rotation.html
- https://docs.suricata.io/en/suricata-8.0.6/rule-management/rule-reload.html
