# Backup package

Install with the normal Stow workflow. Nonsecret backup configuration and small
export helpers belong together here, not in service repositories.

Installed layout:

```
~/.config/resticprofile/
  profiles.yaml          shared destination/credential references and groups
  postgres.yaml          current native PostgreSQL dump backup
  finance.yaml           current direct finance-file backup
  scripts/               PostgreSQL exporter, cleanup and offline tests
  restic-password        private, Git-ignored
  rclone.conf            private, Git-ignored
```

Existing credentials remain in place; do not overwrite them or use stow --adopt.
Runtime dumps and locks remain under ~/.local/state/backup, not in Git.
Run through resticprofile so its job lock covers export/upload/cleanup:

```sh
resticprofile -c ~/.config/resticprofile/profiles.yaml -n postgres backup
resticprofile -c ~/.config/resticprofile/profiles.yaml -n finance-recovery backup
python3 -m unittest discover -s ~/.config/resticprofile/scripts -p test_backup_postgres.py -v
```

PostgreSQL is already restore-tested. The finance direct-file profile is retained
while the simpler broad-home policy is discussed; no completed finance-file
snapshot is claimed here. It has no capture/export hooks and does not preserve
the running API image. Rebuild the API from pushed source and validate it during
migration. Centralizing logic does not imply that all home/service data is yet
covered. No broad-home job, SQLite exports, schedules, alerts or pruning have
been enabled by this move.

## Intended simpler policy (not implemented)

Back up the home directory with a short explicit exclusion list. Add consistent
native exports for live PostgreSQL, MariaDB, SQLite and other valuable mutable
application state where needed. Generic copies of live databases are not the
recovery method. Include actual symlink targets when needed: restic preserves
symlinks without following them. Do not exclude hidden/Git-ignored files as a
class: they contain secrets and valuable runtime state.

Select important outside-home paths too: custom /etc settings and valuable
Docker-volume data that native exports do not already cover. Do not copy all
of /var/lib/docker as a live Docker backup or clone the OS blindly. Privileged
read access is unresolved for the broad scope; unreadable files must not count
as success. Review exclusions for caches/builds, retired apps/Mathesar remnants,
live database stores, sockets and the backup runtime directory. Explicitly keep
prepared exports in scope while excluding partial exports/restore-test folders.

Restore host settings selectively, adapting networking, hardware and paths.
Never replace or duplicate SSH/Tailscale identities blindly. Separate Nautilus
core and Bebop agent repositories remain the intended post-migration ownership.
Current explicit host paths must be reviewed before installing on another host.

Canonical host-specific setup, recovery decisions and migration instructions
live in Obsidian's Homelab notes. Credentials are mode 600, the configuration
folder mode 700, and the independent repository password stays in Bitwarden.
