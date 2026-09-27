#!/usr/bin/env bats

load 'helpers'

setup() {
    setup_common
}

teardown() {
    teardown_common
}

@test "refuses to run when not root" {
    if [ "$(id -u)" -eq 0 ]; then
        skip "this check only applies to a non-root invocation"
    fi
    run "$REPO_ROOT/src/Misc/log-retention.sh"
    [ "$status" -eq 1 ]
    [[ "$output" == *"must be run as root"* ]]
}
