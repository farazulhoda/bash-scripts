#!/bin/bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || echo "$SCRIPT_DIR")"
# shellcheck source=/dev/null
source "$REPO_ROOT/lib/audit_log.sh"
# shellcheck source=/dev/null
source "$REPO_ROOT/lib/authorization.sh"

echo "Enter the target IP address:"
read -r target

require_authorization "scanPlus.sh" "$target"

echo "Enter the starting port number:"
read -r start

echo "Enter the ending port number:"
read -r end

open_ports=""
for port in $(seq "$start" "$end"); do
  (echo >"/dev/tcp/${target}/${port}") &>/dev/null && { echo "$port is open"; open_ports="${open_ports}${port} "; }
done

audit_log "scanPlus.sh" "port_scan" "${target}:${start}-${end}" 0

