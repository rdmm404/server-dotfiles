# Nautilus backups (server-dotfiles / Stow package)

All backup logic lives here. `review/` and preparation YAML have been removed.
This is Nautilus only; retained-agent backup coverage is a separate later scope.

```
~/.config/resticprofile/
  profiles.yaml              broad Nautilus profile + shared Drive settings
  exclude.txt                short explicit source exclusions
  scripts/prepare_backup.py  preparation / successful-upload cleanup
  scripts/backup-postgres.py existing tested PostgreSQL export logic
  scripts/test_*.py          offline tests
  postgres.yaml              proven PostgreSQL-only fallback profile
  restic-password            private, Git-ignored
  rclone.conf                private, Git-ignored
```

Flow: prepare consistent live-state exports -> restic HOME + /etc + exports ->
cleanup exports only after successful upload. Source input paths are ordinary
Python constants and a SQLite path list, not a custom YAML dispatcher. No API
image archive; finance is rebuilt from pushed source.

## Ordinary file coverage

Home includes documents/books/Syncthing, secrets, source/dotfiles, installed CLI,
service settings, completed local HA backup archives and AdGuard leases/filters/
statistics. HA creation stays enabled; disable only HA Drive upload after the
post-migration test successfully restores an HA archive retrieved from restic.
Retain HA's independent encryption key. Do not trust an archive still being
created as the only recovery point; test a completed archive.

AdGuard stats are bbolt, NOT SQLite. Ordinary live-file preservation is best-
effort, not a proven consistent database snapshot. DNS/DHCP are never stopped by
this helper. Validate stats recovery separately before relying on retained
statistics; preserving the file alone does not establish recoverability.
Dynamic lease loss is accepted; static reservations also live in leases.json.
Query logs and login sessions remain excluded.

`/etc` is configuration-reference data, not a full OS image. Restore selectively,
never blindly replace networking or duplicate SSH identities. We do not copy the
OS, /root, all of /var/lib/docker, container images or running Tailscale state.
Any additional valuable outside-home mounts must be explicitly included/exported.
The known PostgreSQL volume outside home is protected by native dumps.

## Special preparation

- PostgreSQL: the same restore-tested exporter, called with a new output folder.
- MariaDB: all non-system DBs, transactional dumps/routines/events/triggers plus
  native system-user/grant export. Reject non-InnoDB application tables.
- SQLite: one online backup operation for HA/Grafana/Gatus/UpSnap, finite wait,
  integrity check, standalone outputs; raw hot DB/WAL/SHM files are excluded.
- Redis: completed BGSAVE -> checked RDB export (no live AOF copy).
- Zigbee2MQTT: supported MQTT request/response, transaction correlation, checked
  ZIP including network/coordinator/pairing state. No routine container stop.
- MQTT: SIGUSR1, wait for the atomic persistence-file replacement, copy/validate
  header. Signal delivery alone is not counted as completion.
- Prometheus: native TSDB snapshot INCLUDING head -> archive with ownership/modes.
  Preserve historical metrics shown in Grafana, not just Grafana dashboards.
  Exclude the raw hot TSDB directory; its exported snapshot is the recovery copy.

Capture results are private mode-700/600 temporary files. Publish only when all
methods succeed and containers are unchanged; on failure retain the previous
complete set, discard partial captures and abort upload. Never use the helpers
directly: the profile lock covers preparation, upload and cleanup.

## Current prerequisites / NOT yet proven end-to-end

No privileged setup, live service capture, production changes or uploads were
performed as part of implementation. Offline tests and merged config loading
are not database recovery proof. The old PostgreSQL-only profile remains usable
until the broad profile is fully tested.

1. Arrange reviewed privileged invocation/read access for /etc and root-owned
   service state. Root-owned state directory: `/var/lib/resticprofile/nautilus`.
   No broad passwordless sudo. Credentials remain in rdmm404's protected path.
2. MQTT dependency is declared inline in `prepare_backup.py` using PEP 723:
   `paho-mqtt==2.1.0`. Both preparation and cleanup run through the existing
   `/home/rdmm404/.local/bin/uv`, using `/usr/bin/python3` without downloading a
   new interpreter. No apt/Python system-package installation is needed. First
   uv invocation needs package-download access; later runs reuse the root-owned
   `/var/cache/uv/nautilus-backup` cache. Prewarm through a harmless import before
   a real backup, not through running preparation. Keep that cache private.
   Do not put credentials on MQTT client argv.
3. Prometheus currently lacks `--web.enable-admin-api`. This helper FAILS in
   read-only preflight before any capture until the native API is enabled.
   That flag ALSO enables destructive APIs: review network/reverse-proxy access
   restrictions before changing it. No flag addition or restart was performed.
   A brief stop/copy alternative is possible but requires a separate decision.
4. Test real MariaDB import (including users/grants), SQLite integrity/content,
   Redis, correlated Zigbee export, MQTT and Prometheus restore. Inputs and exact
   server versions/tools need validation; do not claim complete coverage yet.
5. Check exclusion matching and any symlinks outside source scope. Restic saves
   symlinks, not their targets. Missing/unreadable required sources must fail.
6. UpSnap's two DBs and associated files are not an atomic application-wide set;
   evaluate whether it needs coordination during live testing. No service stop
   is assumed. Ordinary files and multiple DB captures are not globally atomic.
   Final migration still freezes writers and takes a fresh consistent set.

After prerequisites are approved, use an explicitly privileged invocation of
`resticprofile -c /home/rdmm404/.config/resticprofile/profiles.yaml -n nautilus backup`.
Do not initialize/prune a repository, start schedules or enable alerts implicitly.
Manual reads of snapshots/checks do not need root-owned source access.

## Recovery

Retrieve only the wanted file/archive from a snapshot if needed. Native DB dump
imports use matching tools, not raw volume replay. SQLite outputs map to the
source paths in restore-metadata.json; remove obsolete WAL/SHM only with the app
stopped during a reviewed restore. Restore source owner/mode from metadata.
Zigbee ZIP restores its data directory; MQTT/Redis outputs map to their persistence
files. Prometheus tsdb.tar contains a `prometheus/` root with TSDB blocks; restore
while Prometheus is stopped, to the reviewed data directory, with recorded owner/
mode. Import MariaDB user definitions into a fresh compatible instance carefully.
No helper starts/restores/deploys services automatically.

Post-migration: remove retired-app exclusions after reviewed cleanup actually
removes those directories; keeping obsolete exclusions would just be noise.
Scheduling/alerts, 30-day retention, checks/restore schedules and OS rollback
remain deferred. Canonical host-specific decisions live in Obsidian Homelab notes.

Offline tests (no production/Drive access):

```
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s ~/.config/resticprofile/scripts -p 'test_*.py' -v
```

Sources: resticprofile command hooks (run-after is success-only):
https://creativeprojects.github.io/resticprofile/configuration/run_hooks/index.html
Prometheus snapshot API (skip_head=false; admin API prerequisites):
https://prometheus.io/docs/prometheus/latest/querying/api/#snapshot
Zigbee2MQTT backup request:
https://www.zigbee2mqtt.io/guide/usage/mqtt_topics_and_messages.html#zigbee2mqtt-bridge-request-backup
AdGuard uses bbolt internally for statistics:
https://github.com/AdguardTeam/AdGuardHome/blob/master/internal/stats/stats.go
