#!/usr/bin/env bash
# Tests for check_mandatory_sources and discover_optional_sources.

# shellcheck source=/dev/null
source "$REPO_ROOT/scripts/publish-artifacts.sh"

# _make_aidlc_fixture
# Creates a fixture with the .kiro rule-details layout and an empty aidlc-docs
# tree. Caller writes whichever source files they need.
_make_aidlc_fixture() {
  local root
  root="$(mktemp -d)"
  mkdir -p "$root/.kiro/aws-aidlc-rule-details"
  mkdir -p "$root/aidlc-docs/inception/requirements"
  mkdir -p "$root/aidlc-docs/inception/application-design"
  printf '%s' "$root"
}

_write_mandatory() {
  local root="$1"
  printf '# requirements\n' > "$root/aidlc-docs/inception/requirements/requirements.md"
  printf '# application design\n' > "$root/aidlc-docs/inception/application-design/application-design.md"
}

_write_all_optionals() {
  local root="$1"
  printf '# components\n' > "$root/aidlc-docs/inception/application-design/components.md"
  printf '# component methods\n' > "$root/aidlc-docs/inception/application-design/component-methods.md"
  printf '# services\n' > "$root/aidlc-docs/inception/application-design/services.md"
}

# ---------------- check_mandatory_sources ----------------

test_mandatory_present_passes() {
  local fixture
  fixture="$(_make_aidlc_fixture)"
  trap 'rm -rf "$fixture"' RETURN
  _write_mandatory "$fixture"

  check_mandatory_sources "$fixture"
  assert_exit_code 0 $? || return 1
  return 0
}

test_missing_requirements_aborts() {
  local fixture
  fixture="$(_make_aidlc_fixture)"
  trap 'rm -rf "$fixture"' RETURN
  # write only application-design
  printf '# app design\n' > "$fixture/aidlc-docs/inception/application-design/application-design.md"

  local stderr rc
  stderr="$(check_mandatory_sources "$fixture" 2>&1)"
  rc=$?
  assert_exit_code 1 "$rc" || return 1
  assert_contains "$stderr" "requirements/requirements.md" \
    "should name the missing requirements file" || return 1
  return 0
}

test_missing_application_design_aborts() {
  local fixture
  fixture="$(_make_aidlc_fixture)"
  trap 'rm -rf "$fixture"' RETURN
  # write only requirements
  printf '# reqs\n' > "$fixture/aidlc-docs/inception/requirements/requirements.md"

  local stderr rc
  stderr="$(check_mandatory_sources "$fixture" 2>&1)"
  rc=$?
  assert_exit_code 1 "$rc" || return 1
  assert_contains "$stderr" "application-design/application-design.md" \
    "should name the missing application-design file" || return 1
  return 0
}

test_missing_both_lists_both() {
  local fixture
  fixture="$(_make_aidlc_fixture)"
  trap 'rm -rf "$fixture"' RETURN

  local stderr rc
  stderr="$(check_mandatory_sources "$fixture" 2>&1)"
  rc=$?
  assert_exit_code 1 "$rc" || return 1
  assert_contains "$stderr" "requirements/requirements.md" || return 1
  assert_contains "$stderr" "application-design/application-design.md" || return 1
  return 0
}

# ---------------- discover_optional_sources ----------------

test_all_optionals_found() {
  local fixture
  fixture="$(_make_aidlc_fixture)"
  trap 'rm -rf "$fixture"' RETURN
  _write_mandatory "$fixture"
  _write_all_optionals "$fixture"

  local got
  got="$(discover_optional_sources "$fixture" 2>/dev/null)"
  assert_contains "$got" "components.md" || return 1
  assert_contains "$got" "component-methods.md" || return 1
  assert_contains "$got" "services.md" || return 1
  return 0
}

test_no_optionals_found() {
  local fixture
  fixture="$(_make_aidlc_fixture)"
  trap 'rm -rf "$fixture"' RETURN
  _write_mandatory "$fixture"

  local got stderr
  got="$(discover_optional_sources "$fixture" 2>/dev/null)"
  assert_eq "" "$got" "stdout should be empty when no optionals exist" || return 1

  stderr="$(discover_optional_sources "$fixture" 2>&1 >/dev/null)"
  assert_contains "$stderr" "Skipping" || return 1
  assert_contains "$stderr" "components.md" || return 1
  assert_contains "$stderr" "component-methods.md" || return 1
  assert_contains "$stderr" "services.md" || return 1
  return 0
}

test_partial_optionals_found() {
  local fixture
  fixture="$(_make_aidlc_fixture)"
  trap 'rm -rf "$fixture"' RETURN
  _write_mandatory "$fixture"
  printf '# components\n' \
    > "$fixture/aidlc-docs/inception/application-design/components.md"

  local got stderr
  got="$(discover_optional_sources "$fixture" 2>/dev/null)"
  assert_contains "$got" "components.md" || return 1
  # Stdout should NOT contain the missing ones.
  if [[ "$got" == *"component-methods.md"* ]]; then
    printf '    component-methods.md should not appear in stdout\n' >&2
    return 1
  fi
  if [[ "$got" == *"services.md"* ]]; then
    printf '    services.md should not appear in stdout\n' >&2
    return 1
  fi

  stderr="$(discover_optional_sources "$fixture" 2>&1 >/dev/null)"
  assert_contains "$stderr" "Found optional" || return 1
  assert_contains "$stderr" "Skipping" || return 1
  return 0
}

test_optionals_emitted_in_canonical_order() {
  # Even when the filesystem returns files in a different order, we expect
  # the function to walk OPTIONAL_SOURCES in declared order so the manifest's
  # published_files list is deterministic.
  local fixture
  fixture="$(_make_aidlc_fixture)"
  trap 'rm -rf "$fixture"' RETURN
  _write_mandatory "$fixture"
  _write_all_optionals "$fixture"

  local got
  got="$(discover_optional_sources "$fixture" 2>/dev/null)"

  # Expect: components.md, component-methods.md, services.md (in that order).
  local expected
  expected="aidlc-docs/inception/application-design/components.md
aidlc-docs/inception/application-design/component-methods.md
aidlc-docs/inception/application-design/services.md"
  assert_eq "$expected" "$got" || return 1
  return 0
}
