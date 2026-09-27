#!/usr/bin/env bats
# Only covers the validation/authorization paths, which run before any
# network call — this suite makes no live requests to sonar.omnisint.io.

load 'helpers'

setup() {
    setup_common
    export AUTHORIZED_TICKET="CHG-1"
    export HOST_SCAN_OUTPUT_DIR="$BATS_TEST_TMPDIR/host_scan_out"
}

teardown() {
    teardown_common
}

@test "rejects a host containing characters outside [a-zA-Z0-9._-]" {
    run bash -c "printf 'bad host!\n' | '$REPO_ROOT/src/networking-tools/host_scan/host.sh'"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Invalid host"* ]]
}

@test "denies without an authorization ticket" {
    unset AUTHORIZED_TICKET
    run bash -c "printf '127.0.0.1\n' | HOST_SCAN_OUTPUT_DIR='$HOST_SCAN_OUTPUT_DIR' '$REPO_ROOT/src/networking-tools/host_scan/host.sh'"
    [ "$status" -eq 1 ]
    [[ "$output" == *"AUTHORIZED_TICKET"* ]]
}

@test "denies a host not on the allowlist" {
    run bash -c "printf 'example.com\n' | AUTHORIZED_TICKET='$AUTHORIZED_TICKET' HOST_SCAN_OUTPUT_DIR='$HOST_SCAN_OUTPUT_DIR' '$REPO_ROOT/src/networking-tools/host_scan/host.sh'"
    [ "$status" -eq 1 ]
    [[ "$output" == *"not on the approved-targets allowlist"* ]]
}

@test "creates the output directory with mode 700 before writing anything" {
    run bash -c "printf 'bad host!\n' | HOST_SCAN_OUTPUT_DIR='$HOST_SCAN_OUTPUT_DIR' '$REPO_ROOT/src/networking-tools/host_scan/host.sh'"
    [ -d "$HOST_SCAN_OUTPUT_DIR" ]
    perms=$(stat -f '%Lp' "$HOST_SCAN_OUTPUT_DIR" 2>/dev/null || stat -c '%a' "$HOST_SCAN_OUTPUT_DIR")
    [ "$perms" = "700" ]
}
