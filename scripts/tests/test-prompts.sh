#!/usr/bin/env bash
# Tests for warn_if_main and prompt_overwrite.

# shellcheck source=/dev/null
source "$REPO_ROOT/scripts/publish-artifacts.sh"

# ---------------- warn_if_main ----------------

test_warn_if_main_shows_warning_on_main() {
  local stderr rc
  # Pipe "y" as the confirmation answer.
  stderr="$(PUBLISH_ARTIFACTS_BRANCH_OVERRIDE=main warn_if_main 2>&1 \
    < <(printf 'y\n') > /dev/null)"
  rc=$?
  assert_exit_code 0 "$rc" || return 1
  assert_contains "$stderr" 'WARNING' || return 1
  assert_contains "$stderr" 'main' || return 1
  return 0
}

test_warn_if_main_shows_warning_on_master() {
  local stderr rc
  stderr="$(PUBLISH_ARTIFACTS_BRANCH_OVERRIDE=master warn_if_main 2>&1 \
    < <(printf 'y\n') > /dev/null)"
  rc=$?
  assert_exit_code 0 "$rc" || return 1
  assert_contains "$stderr" 'master' || return 1
  return 0
}

test_warn_if_main_aborts_on_n() {
  local rc
  PUBLISH_ARTIFACTS_BRANCH_OVERRIDE=main warn_if_main \
    < <(printf 'n\n') > /dev/null 2>&1
  rc=$?
  assert_exit_code 1 "$rc" || return 1
  return 0
}

test_warn_if_main_aborts_on_empty() {
  local rc
  PUBLISH_ARTIFACTS_BRANCH_OVERRIDE=main warn_if_main \
    < <(printf '\n') > /dev/null 2>&1
  rc=$?
  assert_exit_code 1 "$rc" || return 1
  return 0
}

test_warn_if_main_silent_on_feature_branch() {
  local stderr rc
  stderr="$(PUBLISH_ARTIFACTS_BRANCH_OVERRIDE=vijay warn_if_main 2>&1)"
  rc=$?
  assert_exit_code 0 "$rc" || return 1
  if [[ "$stderr" == *"WARNING"* ]]; then
    printf '    expected no warning on feature branch, got: %s\n' "$stderr" >&2
    return 1
  fi
  return 0
}

test_warn_if_main_silent_when_not_in_git_repo() {
  local rc
  PUBLISH_ARTIFACTS_BRANCH_OVERRIDE="" warn_if_main < /dev/null > /dev/null 2>&1
  rc=$?
  assert_exit_code 0 "$rc" || return 1
  return 0
}

# ---------------- prompt_overwrite ----------------

test_prompt_overwrite_no_prompt_when_target_missing() {
  local fixture
  fixture="$(mktemp -d)"
  trap 'rm -rf "$fixture"' RETURN
  rm -rf "$fixture"  # ensure does not exist

  local rc
  prompt_overwrite "$fixture/missing" < /dev/null > /dev/null 2>&1
  rc=$?
  assert_exit_code 0 "$rc" || return 1
  return 0
}

test_prompt_overwrite_y_returns_success() {
  local fixture
  fixture="$(mktemp -d)"
  trap 'rm -rf "$fixture"' RETURN
  mkdir -p "$fixture/target"

  local rc
  prompt_overwrite "$fixture/target" < <(printf 'y\n') > /dev/null 2>&1
  rc=$?
  assert_exit_code 0 "$rc" || return 1
  return 0
}

test_prompt_overwrite_capital_y_returns_success() {
  local fixture
  fixture="$(mktemp -d)"
  trap 'rm -rf "$fixture"' RETURN
  mkdir -p "$fixture/target"

  local rc
  prompt_overwrite "$fixture/target" < <(printf 'Y\n') > /dev/null 2>&1
  rc=$?
  assert_exit_code 0 "$rc" || return 1
  return 0
}

test_prompt_overwrite_n_aborts() {
  local fixture
  fixture="$(mktemp -d)"
  trap 'rm -rf "$fixture"' RETURN
  mkdir -p "$fixture/target"

  local rc
  prompt_overwrite "$fixture/target" < <(printf 'n\n') > /dev/null 2>&1
  rc=$?
  assert_exit_code 1 "$rc" || return 1
  return 0
}

test_prompt_overwrite_empty_aborts() {
  local fixture
  fixture="$(mktemp -d)"
  trap 'rm -rf "$fixture"' RETURN
  mkdir -p "$fixture/target"

  local rc
  prompt_overwrite "$fixture/target" < <(printf '\n') > /dev/null 2>&1
  rc=$?
  assert_exit_code 1 "$rc" || return 1
  return 0
}

test_prompt_overwrite_message_shows_target_path() {
  local fixture
  fixture="$(mktemp -d)"
  trap 'rm -rf "$fixture"' RETURN
  mkdir -p "$fixture/target"

  local stderr
  stderr="$(prompt_overwrite "$fixture/target" 2>&1 \
    < <(printf 'y\n') > /dev/null)"
  assert_contains "$stderr" "$fixture/target" || return 1
  return 0
}
