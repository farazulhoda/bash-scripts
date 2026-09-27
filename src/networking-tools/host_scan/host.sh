#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || echo "$SCRIPT_DIR")"
# shellcheck source=/dev/null
source "$REPO_ROOT/lib/audit_log.sh"
# shellcheck source=/dev/null
source "$REPO_ROOT/lib/authorization.sh"

# Scan output never lives inside the repo — it's reconnaissance data, not
# source, and a repo directory risks it getting swept up by `git add -A`.
OUTPUT_DIR="${HOST_SCAN_OUTPUT_DIR:-$HOME/.local/share/bash-scripts/host_scan}"
mkdir -p "$OUTPUT_DIR"
chmod 700 "$OUTPUT_DIR"

clear
read -rp "Enter a host: " HOST

# Only allow a plausible hostname/domain — this value is interpolated into
# a URL and a grep pattern below, so anything else gets rejected outright.
if ! [[ "$HOST" =~ ^[a-zA-Z0-9._-]+$ ]]; then
    echo "Invalid host: $HOST" >&2
    exit 1
fi

require_authorization "host.sh" "$HOST"

RAW_FILE="$OUTPUT_DIR/${HOST}.raw.txt"
RESULT_FILE="$OUTPUT_DIR/${HOST}.subdomains.txt"

curl --silent --insecure "https://sonar.omnisint.io/subdomains/${HOST}" > "$RAW_FILE"
exit_code=$?
grep -oE "[a-zA-Z0-9._-]+\.${HOST}" "$RAW_FILE" | sort -u > "$RESULT_FILE"
chmod 600 "$RAW_FILE" "$RESULT_FILE"

num_subdomains=$(wc -l < "$RESULT_FILE")
echo "found: $num_subdomains subdomains (saved to $RESULT_FILE)"

audit_log "host.sh" "subdomain_enum" "$HOST" "$exit_code"
