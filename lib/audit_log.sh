#!/bin/bash
# Shared audit logging for security-relevant script execution.
# CJIS Security Policy §5.4 requires accountability for actions like
# scanning, packet capture, and log/account maintenance — every script
# that touches those areas should source this and call audit_log().

AUDIT_LOG_DIR="${AUDIT_LOG_DIR:-/var/log/cjis-audit}"
AUDIT_LOG_FILE="${AUDIT_LOG_FILE:-$AUDIT_LOG_DIR/script-audit.log}"

_audit_ensure_log() {
    if [ ! -d "$AUDIT_LOG_DIR" ]; then
        mkdir -p "$AUDIT_LOG_DIR" 2>/dev/null
        chmod 750 "$AUDIT_LOG_DIR" 2>/dev/null
    fi
    if [ ! -f "$AUDIT_LOG_FILE" ]; then
        : > "$AUDIT_LOG_FILE" 2>/dev/null
        chmod 640 "$AUDIT_LOG_FILE" 2>/dev/null
    fi
}

# audit_log <script_name> <action> <target> <exit_code>
# Appends one structured line per call. Never fails the caller's script —
# a logging failure must not block or crash the calling tool.
audit_log() {
    local script_name="${1:-unknown}" action="${2:-unknown}" target="${3:-unknown}" exit_code="${4:-0}"
    _audit_ensure_log

    local ts user
    ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    user=$(whoami 2>/dev/null || echo "$USER")

    echo "${ts} user=${user} script=${script_name} action=${action} target=${target} exit_code=${exit_code}" \
        >> "$AUDIT_LOG_FILE" 2>/dev/null

    # Append-only where supported, so a compromised/careless later step
    # can't edit or delete prior entries — only add new ones.
    if command -v chattr >/dev/null 2>&1; then
        chattr +a "$AUDIT_LOG_FILE" 2>/dev/null || true
    fi

    return 0
}
