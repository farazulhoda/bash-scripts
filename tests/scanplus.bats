#!/usr/bin/env bats
# Only covers the authorization gate, which runs before any port probing —
# this suite never actually scans a port.

load 'helpers'

setup() {
    setup_common
}

teardown() {
    teardown_common
}

@test "denies without an authorization ticket" {
    run bash -c "printf '127.0.0.1\n1\n1\n' | '$REPO_ROOT/scanPlus.sh'"
    [ "$status" -eq 1 ]
    [[ "$output" == *"AUTHORIZED_TICKET"* ]]
}

@test "denies a target not on the allowlist" {
    run bash -c "printf '8.8.8.8\n1\n1\n' | AUTHORIZED_TICKET=CHG-1 '$REPO_ROOT/scanPlus.sh'"
    [ "$status" -eq 1 ]
    [[ "$output" == *"not on the approved-targets allowlist"* ]]
}
