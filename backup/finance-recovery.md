# Finance recovery files

The API is rebuilt from the pushed source repository. The current deployed API
image is deliberately not preserved; source/deployment parity is not required
by this backup decision. Validate the rebuilt API during migration.

`~/.config/resticprofile/finance.yaml` contains an ordinary direct-file
resticprofile backup, owned by server-dotfiles. It is included by the shared
configuration and inherits
the encrypted repository, password-file and rclone settings. No custom finance
capture scripts, temporary export set or cleanup hooks are needed.

```sh
resticprofile -c ~/.config/resticprofile/profiles.yaml -n finance-recovery backup
```

It backs up private app `.env`, migration `.env.dbmate`, legacy `.secrets/`,
production Compose and Dockerfile, the installed CLI binary and the retained
agent's `voltr-finance-config.json`. Legacy credentials are preserved without
claiming they are in current use. Source code is already pushed to Git.

The database is NOT in this profile. The separate `postgres` profile uses a
native dump helper because copying a live PostgreSQL data directory is unsafe.
Retrieve both profiles' snapshots for full finance recovery; they are separate
recovery points, not one atomic backup. Avoid editing settings or deploying
while backing up, and take a fresh consistent set during the cutover freeze.

Secrets remain ignored by Git and encrypted on Drive. Explicit host paths must
be reviewed at migration. Missing/unreadable sources must fail the backup;
no-error-on-warning is false. If required inputs are symlinks, restic preserves
the links rather than their target bytes, so review before changing these paths.

For recovery, restore files into a private staging directory, restore/validate
PostgreSQL, rebuild the API from Git and adapt domains/networks for the target.
Do not start migration tools against production or overwrite host configuration
blindly. The agent's client config remains on the agent host; update its endpoint
at coordinated domain cutover. Replacing the bind-mounted CLI requires recreating
the gateway container, not just restarting it. The CLI can also be rebuilt from
source; its saved binary is simply a fallback.

No scheduling, alerts or automatic pruning are enabled. Canonical host-specific
setup and recovery records live in Obsidian's Homelab notes.
