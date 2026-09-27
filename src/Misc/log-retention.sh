#!/bin/bash
set -euo pipefail

# Rotates and archives system logs without ever destroying them, per CJIS
# Security Policy retention requirements (minimum 1 year for audit-relevant
# logs). Replaces the old cleanup.sh/cleanup2.sh, which ran
#   cat /dev/null > /var/log/messages
#   cat /dev/null > /var/log/wtmp
# — that destroys audit trail data outright and is functionally identical
# to anti-forensic log wiping. Never reintroduce that pattern here.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || echo "$SCRIPT_DIR")"
# shellcheck source=/dev/null
source "$REPO_ROOT/lib/audit_log.sh"

LOGROTATE_CONF="$REPO_ROOT/lib/logrotate-cjis.conf"
STATE_FILE="/var/lib/cjis-logrotate.status"

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root (it rotates system logs)." >&2
    exit 1
fi

if ! command -v logrotate >/dev/null 2>&1; then
    echo "logrotate is not installed. Install it yourself and re-run —" >&2
    echo "this script will not silently install packages that touch audit logs." >&2
    audit_log "log-retention.sh" "rotate_logs" "system-logs" 127
    exit 127
fi

set +e
logrotate --state "$STATE_FILE" "$LOGROTATE_CONF"
exit_code=$?
set -e

audit_log "log-retention.sh" "rotate_logs" "system-logs" "$exit_code"

if [ "$exit_code" -eq 0 ]; then
    echo "Logs rotated and archived (compressed, retained per policy). Nothing was deleted."
else
    echo "logrotate exited with code $exit_code — check $LOGROTATE_CONF and $STATE_FILE" >&2
fi

exit "$exit_code"
