#!/bin/bash
set -euo pipefail

# Installs the scoped sudoers policy for live_network_monitor.sh so its
# operators don't need blanket sudo rights — only rights to run tcpdump
# and vnstat with the exact arguments that script uses. This is an
# explicit administrative action: it is never invoked automatically by
# any other script here, and it always validates with visudo before
# touching /etc/sudoers.d.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || echo "$SCRIPT_DIR")"
# shellcheck source=/dev/null
source "$REPO_ROOT/lib/audit_log.sh"

POLICY_SRC="$REPO_ROOT/config/sudoers.d/bash-scripts-network-tools"
POLICY_DST="/etc/sudoers.d/bash-scripts-network-tools"

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root (it writes to /etc/sudoers.d)." >&2
    exit 1
fi

if [ ! -f "$POLICY_SRC" ]; then
    echo "Policy file not found: $POLICY_SRC" >&2
    exit 1
fi

echo "Reviewing policy before install:"
echo "---"
cat "$POLICY_SRC"
echo "---"
read -rp "Install this policy to $POLICY_DST? [y/N] " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Aborted, nothing installed."
    exit 1
fi

if ! visudo -cf "$POLICY_SRC"; then
    echo "Refusing to install: policy failed visudo syntax check." >&2
    audit_log "install-sudoers-policy.sh" "install" "$POLICY_DST" 1
    exit 1
fi

install -m 0440 -o root -g root "$POLICY_SRC" "$POLICY_DST"
audit_log "install-sudoers-policy.sh" "install" "$POLICY_DST" 0

echo "Installed. Add operators with: usermod -aG netmon <username>"
