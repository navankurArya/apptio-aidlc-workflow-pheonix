#!/usr/bin/env bash
# Smoke test — proves the test harness is wired up correctly.

# REPO_ROOT is set by run-tests.sh.

test_publish_script_exists() {
  assert_file_exists "$REPO_ROOT/scripts/publish-artifacts.sh" || return 1
  return 0
}

test_publish_script_is_executable() {
  if [[ ! -x "$REPO_ROOT/scripts/publish-artifacts.sh" ]]; then
    printf "    expected executable: '%s'\n" \
      "$REPO_ROOT/scripts/publish-artifacts.sh" >&2
    return 1
  fi
  return 0
}
