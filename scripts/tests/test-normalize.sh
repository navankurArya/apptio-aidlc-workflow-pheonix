#!/usr/bin/env bash
# Tests for normalize_artifact_name and validate_artifact_name.
#
# Source the script under test once at file scope. Because publish-artifacts.sh
# guards its main() with [[ BASH_SOURCE == 0 ]], sourcing it just defines the
# functions without executing anything.

# shellcheck source=/dev/null
source "$REPO_ROOT/scripts/publish-artifacts.sh"

# ---------------- normalize_artifact_name ----------------

test_normalize_spaces_to_dashes() {
  local got
  got="$(normalize_artifact_name "My Cool Artifact")"
  assert_eq "my-cool-artifact" "$got" || return 1
  return 0
}

test_normalize_collapses_repeated_spaces() {
  local got
  got="$(normalize_artifact_name "My  Cool   Artifact")"
  assert_eq "my-cool-artifact" "$got" || return 1
  return 0
}

test_normalize_lowercases() {
  local got
  got="$(normalize_artifact_name "LABELS")"
  assert_eq "labels" "$got" || return 1
  return 0
}

test_normalize_trims_whitespace() {
  local got
  got="$(normalize_artifact_name "  labels  ")"
  assert_eq "labels" "$got" || return 1
  return 0
}

test_normalize_strips_leading_trailing_dashes() {
  local got
  got="$(normalize_artifact_name "--labels--")"
  assert_eq "labels" "$got" || return 1
  return 0
}

test_normalize_collapses_repeated_dashes() {
  local got
  got="$(normalize_artifact_name "bulk--label---assignment")"
  assert_eq "bulk-label-assignment" "$got" || return 1
  return 0
}

test_normalize_preserves_numbers() {
  local got
  got="$(normalize_artifact_name "v2 artifact")"
  assert_eq "v2-artifact" "$got" || return 1
  return 0
}

test_normalize_mixed_whitespace_and_case() {
  local got
  got="$(normalize_artifact_name "  Bulk LABEL  Assignment  ")"
  assert_eq "bulk-label-assignment" "$got" || return 1
  return 0
}

# ---------------- validate_artifact_name ----------------

test_validate_accepts_simple_name() {
  validate_artifact_name "labels"
  assert_exit_code 0 $? || return 1
  return 0
}

test_validate_accepts_kebab() {
  validate_artifact_name "bulk-label-assignment"
  assert_exit_code 0 $? || return 1
  return 0
}

test_validate_accepts_numbers() {
  validate_artifact_name "v2-artifact"
  assert_exit_code 0 $? || return 1
  return 0
}

test_validate_rejects_underscore() {
  validate_artifact_name "label_v2"
  assert_exit_code 1 $? || return 1
  return 0
}

test_validate_rejects_empty() {
  validate_artifact_name ""
  assert_exit_code 1 $? || return 1
  return 0
}

test_validate_rejects_uppercase() {
  validate_artifact_name "Labels"
  assert_exit_code 1 $? || return 1
  return 0
}

test_validate_rejects_spaces() {
  validate_artifact_name "my artifact"
  assert_exit_code 1 $? || return 1
  return 0
}

test_validate_rejects_leading_dash() {
  validate_artifact_name "-labels"
  assert_exit_code 1 $? || return 1
  return 0
}

test_validate_rejects_trailing_dash() {
  validate_artifact_name "labels-"
  assert_exit_code 1 $? || return 1
  return 0
}

test_validate_rejects_double_dash() {
  validate_artifact_name "labels--v2"
  assert_exit_code 1 $? || return 1
  return 0
}
