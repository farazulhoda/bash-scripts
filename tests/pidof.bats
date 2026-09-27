#!/usr/bin/env bats

load 'helpers'

setup() {
    setup_common
}

teardown() {
    teardown_common
}

@test "reports the process was not running and exits 2" {
    run "$REPO_ROOT/src/Misc/pidof.sh"
    [ "$status" -eq 2 ]
    [[ "$output" == *"was not running"* ]]
    [[ "$output" == *"Nothing killed"* ]]
}
