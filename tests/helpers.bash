#!/usr/bin/env bash
# Shared setup for bats tests. Keeps every test's audit log isolated in a
# throwaway temp dir so tests never touch /var/log/cjis-audit or race
# each other.

setup_common() {
    REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." && pwd)"
    export REPO_ROOT

    AUDIT_TMP="$(mktemp -d)"
    export AUDIT_LOG_DIR="$AUDIT_TMP"
    export AUDIT_LOG_FILE="$AUDIT_TMP/audit.log"

    # `clear` (used by host.sh) errors out without a known terminal type.
    export TERM="${TERM:-xterm}"
}

teardown_common() {
    [ -n "${AUDIT_TMP:-}" ] && rm -rf "$AUDIT_TMP"
}
