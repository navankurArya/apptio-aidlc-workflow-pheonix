#!/usr/bin/env bash
# Tests for resolve_docs_root.

# shellcheck source=/dev/null
source "$REPO_ROOT/scripts/publish-artifacts.sh"

# _make_fixture <subdir-name> [<deep-path>]
# Creates a temporary fixture root, mkdir's the chosen rule-details layout
# inside it, and (if deep-path is given) creates that as well. Echoes the
# fixture root. Caller is responsible for cleanup via trap.
_make_fixture() {
  local layout="$1"
  local deep="${2:-}"
  local root
  root="$(mktemp -d)"
  mkdir -p "$root/$layout"
  if [[ -n "$deep" ]]; then
    mkdir -p "$root/$deep"
  fi
  printf '%s' "$root"
}

test_resolves_kiro_layout() {
  local fixture
  fixture="$(_make_fixture ".kiro/aws-aidlc-rule-details")"
  trap 'rm -rf "$fixture"' RETURN

  local got
  got="$(resolve_docs_root "$fixture")" || return 1
  assert_eq "$fixture" "$got" || return 1
  return 0
}

test_resolves_aidlc_rule_details_layout() {
  local fixture
  fixture="$(_make_fixture ".aidlc-rule-details")"
  trap 'rm -rf "$fixture"' RETURN

  local got
  got="$(resolve_docs_root "$fixture")" || return 1
  assert_eq "$fixture" "$got" || return 1
  return 0
}

test_resolves_aidlc_aidlc_rules_layout() {
  local fixture
  fixture="$(_make_fixture ".aidlc/aidlc-rules/aws-aidlc-rule-details")"
  trap 'rm -rf "$fixture"' RETURN

  local got
  got="$(resolve_docs_root "$fixture")" || return 1
  assert_eq "$fixture" "$got" || return 1
  return 0
}

test_resolves_amazonq_layout() {
  local fixture
  fixture="$(_make_fixture ".amazonq/aws-aidlc-rule-details")"
  trap 'rm -rf "$fixture"' RETURN

  local got
  got="$(resolve_docs_root "$fixture")" || return 1
  assert_eq "$fixture" "$got" || return 1
  return 0
}

test_walks_up_directory_tree() {
  # Rule-details at fixture root, but we invoke from a nested subdir.
  local fixture
  fixture="$(_make_fixture ".kiro/aws-aidlc-rule-details" "deep/sub/dir")"
  trap 'rm -rf "$fixture"' RETURN

  local got
  got="$(resolve_docs_root "$fixture/deep/sub/dir")" || return 1
  assert_eq "$fixture" "$got" || return 1
  return 0
}

test_aborts_when_no_rule_details_found() {
  # Fixture with no rule-details layout anywhere up the tree. We point at a
  # tmp dir under TMPDIR, walk up to /, find nothing.
  local fixture
  fixture="$(mktemp -d)"
  trap 'rm -rf "$fixture"' RETURN

  local got rc
  got="$(resolve_docs_root "$fixture" 2>/dev/null)"
  rc=$?
  assert_exit_code 1 "$rc" || return 1
  assert_eq "" "$got" || return 1
  return 0
}

test_abort_message_lists_searched_paths() {
  local fixture
  fixture="$(mktemp -d)"
  trap 'rm -rf "$fixture"' RETURN

  local stderr
  stderr="$(resolve_docs_root "$fixture" 2>&1 >/dev/null)" || true
  assert_contains "$stderr" ".kiro/aws-aidlc-rule-details" \
    "abort message should list .kiro path" || return 1
  assert_contains "$stderr" ".aidlc-rule-details" \
    "abort message should list .aidlc-rule-details path" || return 1
  assert_contains "$stderr" ".amazonq/aws-aidlc-rule-details" \
    "abort message should list .amazonq path" || return 1
  return 0
}
