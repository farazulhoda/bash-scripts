#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || echo "$SCRIPT_DIR")"
# shellcheck source=/dev/null
source "$REPO_ROOT/lib/audit_log.sh"
# shellcheck source=/dev/null
source "$REPO_ROOT/lib/authorization.sh"

SERVER="${HOST:?Set HOST to the scan target, e.g. HOST=127.0.0.1 ./nmap.sh}"
PORT_NUMBER=8080                        # HTTPS port.

require_authorization "nmap.sh" "$SERVER"

set +e
nmap "$SERVER" | grep -w "$PORT_NUMBER"  # Is that particular port open?
#              grep -w matches whole words only,
#+             so this wouldn't match port 1025, for example.
exit_code=$?
set -e

audit_log "nmap.sh" "port_scan" "${SERVER}:${PORT_NUMBER}" "$exit_code"
exit "$exit_code"

# 25/tcp     open        smtp
