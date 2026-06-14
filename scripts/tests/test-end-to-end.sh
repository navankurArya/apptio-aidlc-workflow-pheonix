#!/usr/bin/env bash
# End-to-end tests for copy_files + write_manifest.
#
# These tests don't drive main() (which would require simulating the prompt
# loop with a here-doc); instead they call copy_files and write_manifest
# directly with the same inputs main() would build.

# shellcheck source=/dev/null
source "$REPO_ROOT/scripts/publish-artifacts.sh"

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
  printf '# Requirements — Test Artifact\nCONTENT_REQ\n' \
    > "$root/aidlc-docs/inception/requirements/requirements.md"
  printf '# Application Design — Test Artifact\nCONTENT_APPDESIGN\n' \
    > "$root/aidlc-docs/inception/application-design/application-design.md"
}

# build_sources_string <docs-root> <newline-optionals>
# Mirrors the assembly logic in main() so tests can pass the same input that
# main() would.
_build_sources() {
  local optionals="$1"
  local s=""
  local rel
  for rel in "${MANDATORY_SOURCES[@]}"; do
    s+="$rel"$'\n'
  done
  if [[ -n "$optionals" ]]; then
    s+="$optionals"$'\n'
  fi
  printf '%s' "${s%$'\n'}"
}

# ---------------- copy_files + write_manifest ----------------

test_publishes_minimal_artifact() {
  local fixture
  fixture="$(_make_aidlc_fixture)"
  trap 'rm -rf "$fixture"' RETURN
  _write_mandatory "$fixture"

  local artifact="test-artifact"
  local target_root="$fixture/generated-docs/artifacts/$artifact"
  local sources
  sources="$(_build_sources "")"
  local published
  published="$(copy_files "$fixture" "$artifact" "$sources")"

  PUBLISH_ARTIFACTS_BRANCH_OVERRIDE=vijay \
  PUBLISH_ARTIFACTS_SHA_OVERRIDE=abc123 \
  PUBLISH_ARTIFACTS_REMOTE_OVERRIDE=apptio-aidlc-workflow-ct \
    write_manifest "$target_root" "$artifact" "$published"

  assert_file_exists "$target_root/requirements.md" || return 1
  assert_file_exists "$target_root/application-design/application-design.md" || return 1
  assert_file_exists "$target_root/manifest.yaml" || return 1

  # Optional files must NOT be present.
  if [[ -e "$target_root/application-design/components.md" ]]; then
    printf '    components.md should not exist when source absent\n' >&2
    return 1
  fi

  local manifest
  manifest="$(<"$target_root/manifest.yaml")"
  assert_contains "$manifest" 'artifact: test-artifact' || return 1
  assert_contains "$manifest" 'publish_method: shell' || return 1
  assert_contains "$manifest" 'branch: vijay' || return 1
  assert_contains "$manifest" 'sha: abc123' || return 1
  assert_contains "$manifest" 'central_repo: apptio-aidlc-workflow-ct' || return 1
  assert_contains "$manifest" '- requirements.md' || return 1
  assert_contains "$manifest" '- application-design/application-design.md' || return 1
  return 0
}

test_publishes_full_artifact() {
  local fixture
  fixture="$(_make_aidlc_fixture)"
  trap 'rm -rf "$fixture"' RETURN
  _write_mandatory "$fixture"
  printf '# components\n' > "$fixture/aidlc-docs/inception/application-design/components.md"
  printf '# component methods\n' > "$fixture/aidlc-docs/inception/application-design/component-methods.md"
  printf '# services\n' > "$fixture/aidlc-docs/inception/application-design/services.md"

  local artifact="full-artifact"
  local target_root="$fixture/generated-docs/artifacts/$artifact"
  local optionals
  optionals="$(discover_optional_sources "$fixture" 2>/dev/null)"
  local sources
  sources="$(_build_sources "$optionals")"
  local published
  published="$(copy_files "$fixture" "$artifact" "$sources")"

  PUBLISH_ARTIFACTS_BRANCH_OVERRIDE=vijay \
  PUBLISH_ARTIFACTS_SHA_OVERRIDE=abc123 \
  PUBLISH_ARTIFACTS_REMOTE_OVERRIDE=test-fork \
    write_manifest "$target_root" "$artifact" "$published"

  assert_file_exists "$target_root/requirements.md" || return 1
  assert_file_exists "$target_root/application-design/application-design.md" || return 1
  assert_file_exists "$target_root/application-design/components.md" || return 1
  assert_file_exists "$target_root/application-design/component-methods.md" || return 1
  assert_file_exists "$target_root/application-design/services.md" || return 1

  local manifest
  manifest="$(<"$target_root/manifest.yaml")"
  assert_contains "$manifest" '- application-design/components.md' || return 1
  assert_contains "$manifest" '- application-design/component-methods.md' || return 1
  assert_contains "$manifest" '- application-design/services.md' || return 1
  return 0
}

test_publishes_partial_optionals() {
  local fixture
  fixture="$(_make_aidlc_fixture)"
  trap 'rm -rf "$fixture"' RETURN
  _write_mandatory "$fixture"
  printf '# components\n' > "$fixture/aidlc-docs/inception/application-design/components.md"

  local artifact="partial-artifact"
  local target_root="$fixture/generated-docs/artifacts/$artifact"
  local optionals
  optionals="$(discover_optional_sources "$fixture" 2>/dev/null)"
  local sources
  sources="$(_build_sources "$optionals")"
  local published
  published="$(copy_files "$fixture" "$artifact" "$sources")"

  PUBLISH_ARTIFACTS_BRANCH_OVERRIDE=vijay \
  PUBLISH_ARTIFACTS_SHA_OVERRIDE=abc \
  PUBLISH_ARTIFACTS_REMOTE_OVERRIDE=fork \
    write_manifest "$target_root" "$artifact" "$published"

  assert_file_exists "$target_root/application-design/components.md" || return 1
  if [[ -e "$target_root/application-design/component-methods.md" ]]; then
    printf '    component-methods.md should not exist\n' >&2
    return 1
  fi
  if [[ -e "$target_root/application-design/services.md" ]]; then
    printf '    services.md should not exist\n' >&2
    return 1
  fi

  local manifest
  manifest="$(<"$target_root/manifest.yaml")"
  assert_contains "$manifest" '- application-design/components.md' || return 1
  if [[ "$manifest" == *"- application-design/component-methods.md"* ]]; then
    printf '    manifest should not list component-methods.md\n' >&2
    return 1
  fi
  if [[ "$manifest" == *"- application-design/services.md"* ]]; then
    printf '    manifest should not list services.md\n' >&2
    return 1
  fi
  return 0
}

test_overwrite_replaces_existing_content() {
  local fixture
  fixture="$(_make_aidlc_fixture)"
  trap 'rm -rf "$fixture"' RETURN
  _write_mandatory "$fixture"

  local artifact="overwrite-artifact"
  local target_root="$fixture/generated-docs/artifacts/$artifact"

  # Pre-create stale content.
  mkdir -p "$target_root/application-design"
  printf 'STALE\n' > "$target_root/requirements.md"
  printf 'STALE\n' > "$target_root/stale-extra-file.md"

  local sources
  sources="$(_build_sources "")"
  copy_files "$fixture" "$artifact" "$sources" > /dev/null

  # Stale extra file must be gone (target dir was wiped).
  if [[ -e "$target_root/stale-extra-file.md" ]]; then
    printf '    stale-extra-file.md should be wiped on overwrite\n' >&2
    return 1
  fi

  # New requirements.md must contain the source content, not STALE.
  local content
  content="$(<"$target_root/requirements.md")"
  assert_contains "$content" 'CONTENT_REQ' || return 1
  if [[ "$content" == *"STALE"* ]]; then
    printf '    stale content not replaced\n' >&2
    return 1
  fi
  return 0
}

test_published_file_contents_match_source() {
  local fixture
  fixture="$(_make_aidlc_fixture)"
  trap 'rm -rf "$fixture"' RETURN
  _write_mandatory "$fixture"

  local artifact="content-artifact"
  local target_root="$fixture/generated-docs/artifacts/$artifact"
  local sources
  sources="$(_build_sources "")"
  copy_files "$fixture" "$artifact" "$sources" > /dev/null

  local got
  got="$(<"$target_root/requirements.md")"
  assert_contains "$got" 'CONTENT_REQ' || return 1
  got="$(<"$target_root/application-design/application-design.md")"
  assert_contains "$got" 'CONTENT_APPDESIGN' || return 1
  return 0
}

test_manifest_includes_iso_8601_timestamp() {
  local fixture
  fixture="$(_make_aidlc_fixture)"
  trap 'rm -rf "$fixture"' RETURN
  _write_mandatory "$fixture"

  local artifact="ts-artifact"
  local target_root="$fixture/generated-docs/artifacts/$artifact"
  local sources
  sources="$(_build_sources "")"
  local published
  published="$(copy_files "$fixture" "$artifact" "$sources")"

  PUBLISH_ARTIFACTS_BRANCH_OVERRIDE=vijay \
  PUBLISH_ARTIFACTS_SHA_OVERRIDE=abc \
  PUBLISH_ARTIFACTS_REMOTE_OVERRIDE=fork \
    write_manifest "$target_root" "$artifact" "$published"

  local manifest
  manifest="$(<"$target_root/manifest.yaml")"
  # Match published_at: YYYY-MM-DDTHH:MM:SSZ
  if [[ ! "$manifest" =~ published_at:\ [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z ]]; then
    printf '    manifest missing ISO-8601 published_at:\n%s\n' "$manifest" >&2
    return 1
  fi
  return 0
}
