#!/bin/bash
# Authorization gate for scan/capture tools. CJIS-adjacent environments
# require scanning and monitoring to be explicitly authorized, not just
# recorded after the fact — this checks a target against an approved-
# targets allowlist and requires a ticket/work-order reference before the
# caller is allowed to proceed. Depends on audit_log() (source
# lib/audit_log.sh first).

AUTH_ALLOWLIST="${AUTH_ALLOWLIST:-$REPO_ROOT/config/approved_targets.txt}"

# require_authorization <script_name> <target>
# Exits the calling script if AUTHORIZED_TICKET is unset or the target
# isn't on the allowlist. Every denial and grant is audit-logged.
require_authorization() {
    local script_name="$1" target="$2"

    if [ -z "${AUTHORIZED_TICKET:-}" ]; then
        echo "Refusing to run: set AUTHORIZED_TICKET to the change/work-order reference authorizing this action." >&2
        audit_log "$script_name" "authorization_denied" "$target" 1
        exit 1
    fi

    if [ ! -f "$AUTH_ALLOWLIST" ]; then
        echo "Refusing to run: no approved-targets allowlist found at $AUTH_ALLOWLIST." >&2
        audit_log "$script_name" "authorization_denied" "$target" 1
        exit 1
    fi

    local pattern matched=0
    while IFS= read -r pattern; do
        [ -z "$pattern" ] && continue
        case "$pattern" in
            \#*) continue ;;
        esac
        # shellcheck disable=SC2254  # unquoted on purpose: allowlist entries are globs
        case "$target" in
            $pattern) matched=1; break ;;
        esac
    done < "$AUTH_ALLOWLIST"

    if [ "$matched" -ne 1 ]; then
        echo "Refusing to run: '$target' is not on the approved-targets allowlist ($AUTH_ALLOWLIST)." >&2
        audit_log "$script_name" "authorization_denied" "$target" 1
        exit 1
    fi

    audit_log "$script_name" "authorization_granted" "${target} (ticket=${AUTHORIZED_TICKET})" 0
}
