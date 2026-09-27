#!/usr/bin/env bats
# Uses a stub `nmap` on PATH so these tests never touch the network.

load 'helpers'

setup() {
    setup_common
    STUB_DIR="$BATS_TEST_TMPDIR/bin"
    mkdir -p "$STUB_DIR"
    cat > "$STUB_DIR/nmap" <<'EOS'
#!/bin/bash
echo "8080/tcp open  http-proxy"
EOS
    chmod +x "$STUB_DIR/nmap"
    export PATH="$STUB_DIR:$PATH"
    export AUTHORIZED_TICKET="CHG-1"
}

teardown() {
    teardown_common
}

@test "denies without an authorization ticket" {
    unset AUTHORIZED_TICKET
    export HOST=127.0.0.1
    run "$REPO_ROOT/src/networking-tools/nmap/nmap.sh"
    [ "$status" -eq 1 ]
    [[ "$output" == *"AUTHORIZED_TICKET"* ]]
}

@test "denies a target not on the allowlist" {
    export HOST=8.8.8.8
    run "$REPO_ROOT/src/networking-tools/nmap/nmap.sh"
    [ "$status" -eq 1 ]
    [[ "$output" == *"not on the approved-targets allowlist"* ]]
}

@test "finds the open port for an approved, authorized target" {
    export HOST=127.0.0.1
    run "$REPO_ROOT/src/networking-tools/nmap/nmap.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"8080"* ]]
}

@test "fails clearly when HOST is unset" {
    unset HOST
    run "$REPO_ROOT/src/networking-tools/nmap/nmap.sh"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Set HOST"* ]]
}
