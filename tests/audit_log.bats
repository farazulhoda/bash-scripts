#!/usr/bin/env bats

load 'helpers'

setup() {
    setup_common
    # shellcheck source=/dev/null
    source "$REPO_ROOT/lib/audit_log.sh"
}

teardown() {
    teardown_common
}

@test "creates the log dir and file with restrictive permissions" {
    # audit_log only chmods the dir/file it creates itself, so point at a
    # path that doesn't exist yet rather than the pre-made mktemp -d dir.
    export AUDIT_LOG_DIR="$AUDIT_TMP/nested"
    export AUDIT_LOG_FILE="$AUDIT_LOG_DIR/audit.log"
    audit_log "test.sh" "demo" "target1" 0
    [ -d "$AUDIT_LOG_DIR" ]
    [ -f "$AUDIT_LOG_FILE" ]

    perms_dir=$(stat -f '%Lp' "$AUDIT_LOG_DIR" 2>/dev/null || stat -c '%a' "$AUDIT_LOG_DIR")
    perms_file=$(stat -f '%Lp' "$AUDIT_LOG_FILE" 2>/dev/null || stat -c '%a' "$AUDIT_LOG_FILE")
    [ "$perms_dir" = "750" ]
    [ "$perms_file" = "640" ]
}

@test "appends a structured line with all fields" {
    audit_log "test.sh" "demo" "target1" 3
    run cat "$AUDIT_LOG_FILE"
    [[ "$output" == *"script=test.sh"* ]]
    [[ "$output" == *"action=demo"* ]]
    [[ "$output" == *"target=target1"* ]]
    [[ "$output" == *"exit_code=3"* ]]
}

@test "multiple calls append rather than overwrite" {
    audit_log "test.sh" "first" "t1" 0
    audit_log "test.sh" "second" "t2" 0
    [ "$(wc -l < "$AUDIT_LOG_FILE")" -eq 2 ]
}

@test "never fails the caller even if the log directory can't be created" {
    touch "$BATS_TEST_TMPDIR/notadir"
    export AUDIT_LOG_DIR="$BATS_TEST_TMPDIR/notadir/sub"
    export AUDIT_LOG_FILE="$AUDIT_LOG_DIR/audit.log"
    run audit_log "test.sh" "demo" "target1" 0
    [ "$status" -eq 0 ]
}
