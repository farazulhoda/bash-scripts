# Security & Compliance Notes

This repo contains scan, capture, and system-maintenance scripts. Several
of them touch things that matter for audit and compliance purposes
(CJIS-adjacent environments in particular). This document is the policy
those scripts are built against — read it before running anything here
against a real target, and update it if the design changes.

## Scope of concern

- **Scanning/enumeration**: `src/networking-tools/nmap/nmap.sh`,
  `src/networking-tools/host_scan/host.sh`, `scanPlus.sh`
- **Packet capture / live monitoring**: `src/networking-tools/live_network_monitor.sh`
- **Log/audit-trail maintenance**: `src/Misc/log-retention.sh`

## Authorization

Every scan or capture script requires:

1. `AUTHORIZED_TICKET` set to a change/work-order reference for the action.
2. The target (hostname, IP, or network interface) to be present in
   `config/approved_targets.txt`.

Both checks are enforced by `lib/authorization.sh` (`require_authorization`)
and run before any network action. **This allowlist is not self-service.**
Additions to `config/approved_targets.txt` should map to an actual approved
engagement or maintenance window and go through the same review as any
other change to this repo — do not add a target to unblock a one-off run.

## Audit trail

Every security-relevant script sources `lib/audit_log.sh` and records:
timestamp (UTC), invoking user, script name, action, target, and exit
code, including authorization grants and denials. Logs are written to
`/var/log/cjis-audit/script-audit.log` (override with `AUDIT_LOG_DIR` /
`AUDIT_LOG_FILE`), created at `0640`/`0750`, and made append-only via
`chattr +a` where supported. Do not disable or bypass this logging, and
do not manually edit or truncate the audit log — if entries need
correcting, that itself should go through your incident/change process.

## Log retention

`log-retention.sh` (formerly `cleanup.sh`/`cleanup2.sh`) rotates and
compresses `/var/log/messages` and `/var/log/wtmp` via `logrotate` using
`lib/logrotate-cjis.conf` — it never truncates or deletes logs directly.
The current policy keeps 12 monthly rotations. **Do not reintroduce
`cat /dev/null > <logfile>` or any other direct-truncation pattern** —
that destroys audit trail data and is functionally identical to
anti-forensic log wiping, which is why the original scripts were
replaced.

## Privileged access

`live_network_monitor.sh` needs root to run `tcpdump`. Rather than
requiring operators to hold general sudo rights, use the scoped policy in
`config/sudoers.d/bash-scripts-network-tools`, installed via
`scripts/install-sudoers-policy.sh` (root-run, confirmation-gated, never
auto-invoked). That grants the `netmon` group passwordless rights to run
only the exact `tcpdump` invocations the script uses — nothing broader.

None of these scripts silently install packages with `sudo`. If a
required tool is missing, they fail with an explicit message instead —
package installation on a system with audit/monitoring requirements
needs a change record, not a script deciding on your behalf.

## Data classification of script output

Scan output (subdomain enumeration, host discovery results, packet
captures) is treated as sensitive network-topology data:

- It is never written into this repository or committed to git —
  `host.sh` writes to `~/.local/share/bash-scripts/host_scan/` (`0700`
  dir, `0600` files) instead of its own script directory.
- `.gitignore` also blocks common output patterns (`subdomains*.txt`,
  `*.pcap`) as a second layer, but the primary control is "don't write it
  into the repo tree in the first place."
- Treat any output these scripts produce as you would other CJI-adjacent
  data: don't forward it over unencrypted channels, and don't retain it
  longer than the engagement that authorized it requires.

## CI

Every push/PR to `master` runs ShellCheck, gitleaks, and the bats-core
test suite under `tests/` (`.github/workflows/ci.yml`). A red CI run on
any of these should block merge — fix the finding rather than
suppressing the check, unless it's a deliberate, commented false
positive (see `lib/authorization.sh`'s `SC2254` suppression for an
example of how to document one).

Tests in `tests/` only exercise validation and authorization paths —
they never make live network calls (no real `curl`/`nmap`/port probes),
so CI runs never touch the network or require real scan targets.

## Reporting a problem

This is a personal-use script collection, not a maintained product with
an SLA. If you find a security issue in one of these scripts, open an
issue or PR describing the problem — there is no separate private
disclosure channel.
