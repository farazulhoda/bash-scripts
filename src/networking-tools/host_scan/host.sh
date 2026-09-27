#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || echo "$SCRIPT_DIR")"
# shellcheck source=/dev/null
source "$REPO_ROOT/lib/audit_log.sh"

clear
read -rp "Enter a host: " HOST

# Only allow a plausible hostname/domain — this value is interpolated into
# a URL and a grep pattern below, so anything else gets rejected outright.
if ! [[ "$HOST" =~ ^[a-zA-Z0-9._-]+$ ]]; then
    echo "Invalid host: $HOST" >&2
    exit 1
fi

curl --silent --insecure "https://sonar.omnisint.io/subdomains/${HOST}" > "$SCRIPT_DIR/subdomains1.txt"
exit_code=$?
grep -oE "[a-zA-Z0-9._-]+\.${HOST}" "$SCRIPT_DIR/subdomains1.txt" | sort -u > "$SCRIPT_DIR/subdomains2.txt"
chmod 600 "$SCRIPT_DIR/subdomains1.txt" "$SCRIPT_DIR/subdomains2.txt"

num_subdomains=$(wc -l < "$SCRIPT_DIR/subdomains2.txt")
echo "found: $num_subdomains subdomains"

audit_log "host.sh" "subdomain_enum" "$HOST" "$exit_code"
