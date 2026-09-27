#!/usr/bin/env bats

load 'helpers'

setup() {
    setup_common
    # shellcheck source=/dev/null
    source "$REPO_ROOT/lib/audit_log.sh"
    # shellcheck source=/dev/null
    source "$REPO_ROOT/lib/authorization.sh"
    unset AUTHORIZED_TICKET
}

teardown() {
    teardown_common
}

@test "denies when AUTHORIZED_TICKET is unset" {
    run require_authorization "test.sh" "127.0.0.1"
    [ "$status" -eq 1 ]
    [[ "$output" == *"AUTHORIZED_TICKET"* ]]
    grep -q "action=authorization_denied" "$AUDIT_LOG_FILE"
}

@test "denies when the target is not on the allowlist" {
    export AUTHORIZED_TICKET="CHG-1"
    run require_authorization "test.sh" "8.8.8.8"
    [ "$status" -eq 1 ]
    [[ "$output" == *"not on the approved-targets allowlist"* ]]
    grep -q "action=authorization_denied" "$AUDIT_LOG_FILE"
}

@test "allows an approved target once a ticket is set" {
    export AUTHORIZED_TICKET="CHG-1"
    run require_authorization "test.sh" "127.0.0.1"
    [ "$status" -eq 0 ]
    grep -q "action=authorization_granted" "$AUDIT_LOG_FILE"
    grep -q "ticket=CHG-1" "$AUDIT_LOG_FILE"
}

@test "supports glob patterns in the allowlist" {
    export AUTHORIZED_TICKET="CHG-1"
    export AUTH_ALLOWLIST="$BATS_TEST_TMPDIR/allow.txt"
    echo "10.0.0.*" > "$AUTH_ALLOWLIST"
    run require_authorization "test.sh" "10.0.0.42"
    [ "$status" -eq 0 ]
}

@test "denies when the allowlist file is missing" {
    export AUTHORIZED_TICKET="CHG-1"
    export AUTH_ALLOWLIST="$BATS_TEST_TMPDIR/does-not-exist.txt"
    run require_authorization "test.sh" "127.0.0.1"
    [ "$status" -eq 1 ]
    [[ "$output" == *"no approved-targets allowlist found"* ]]
}
