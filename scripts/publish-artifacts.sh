#!/usr/bin/env bash
# publish-artifacts.sh — promote AIDLC inception docs from a feature branch
# into <DOCS-ROOT>/generated-docs/artifacts/<artifact-name>/ so the team can
# raise a PR onto their fork's main branch.
#
# Pure bash + git only. No external dependencies.
#
# Usage:   ./scripts/publish-artifacts.sh
# Tests:   ./scripts/tests/run-tests.sh
#
# Functions are defined at the top so they can be sourced and unit-tested in
# isolation; main() runs only when the script is executed directly.

set -uo pipefail
# Note: `set -e` is intentionally not used at script scope. Functions return
# non-zero on validation failures and main() handles them explicitly.

# ---------------------------------------------------------------------------
# Artifact-name normalization and validation
# ---------------------------------------------------------------------------

# normalize_artifact_name <raw-input>
# Echoes the normalized name to stdout. Always returns 0; validation is a
# separate step.
#
# Rules:
#   - lowercase
#   - trim leading/trailing whitespace
#   - any run of whitespace -> single dash
#   - collapse repeated dashes
#   - strip leading/trailing dashes
normalize_artifact_name() {
  local raw="${1-}"
  local s="$raw"

  if [[ "${BASH_VERSINFO[0]:-3}" -ge 4 ]]; then
    s="${s,,}"
  else
    s="$(printf '%s' "$s" | tr '[:upper:]' '[:lower:]')"
  fi

  # Replace any run of whitespace with a single dash.
  s="$(printf '%s' "$s" | sed -E 's/[[:space:]]+/-/g')"
  # Collapse repeated dashes.
  s="$(printf '%s' "$s" | sed -E 's/-+/-/g')"
  # Strip leading and trailing dashes.
  while [[ "$s" == -* ]]; do s="${s#-}"; done
  while [[ "$s" == *- ]]; do s="${s%-}"; done

  printf '%s' "$s"
}

# validate_artifact_name <normalized-name>
# Returns 0 if the input matches ^[a-z0-9]+(-[a-z0-9]+)*$, else 1.
validate_artifact_name() {
  local name="${1-}"
  if [[ -z "$name" ]]; then
    return 1
  fi
  if [[ "$name" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
    return 0
  fi
  return 1
}

# prompt_artifact_name
# Reads from stdin in a retype loop. Echoes the validated normalized name on
# stdout. Returns 0 on success, non-zero only if stdin closes without a valid
# entry.
prompt_artifact_name() {
  local raw normalized
  while true; do
    printf 'Artifact name (e.g. "labels" or "Bulk Label Assignment"): ' >&2
    if ! IFS= read -r raw; then
      printf 'No input received. Aborting.\n' >&2
      return 1
    fi
    normalized="$(normalize_artifact_name "$raw")"
    if validate_artifact_name "$normalized"; then
      printf 'Using artifact name: %s\n' "$normalized" >&2
      printf '%s' "$normalized"
      return 0
    fi
    printf 'Invalid artifact name. After normalization: "%s"\n' "$normalized" >&2
    printf 'Names must be lowercase kebab-case (letters, numbers, dashes).\n' >&2
    printf 'Examples: labels, bulk-label-assignment, v2-artifact\n\n' >&2
  done
}

# ---------------------------------------------------------------------------
# <DOCS-ROOT> resolution
# ---------------------------------------------------------------------------

# Rule-details paths probed by core-workflow.md, in priority order.
RULE_DETAILS_PATHS=(
  ".aidlc/aidlc-rules/aws-aidlc-rule-details"
  ".aidlc-rule-details"
  ".kiro/aws-aidlc-rule-details"
  ".amazonq/aws-aidlc-rule-details"
)

# resolve_docs_root <starting-dir>
# Walks up from <starting-dir> looking for any directory that contains one of
# the four rule-details paths. Echoes the matching <DOCS-ROOT> on stdout and
# returns 0 on success. On failure prints the search trail to stderr and
# returns 1.
resolve_docs_root() {
  local start="${1:-.}"
  local dir
  dir="$(cd "$start" 2>/dev/null && pwd)" || {
    printf 'resolve_docs_root: starting directory not accessible: %s\n' \
      "$start" >&2
    return 1
  }

  while :; do
    local rel
    for rel in "${RULE_DETAILS_PATHS[@]}"; do
      if [[ -d "$dir/$rel" ]]; then
        printf '%s' "$dir"
        return 0
      fi
    done
    if [[ "$dir" == "/" ]]; then
      break
    fi
    dir="$(dirname "$dir")"
  done

  {
    printf 'Could not resolve <DOCS-ROOT> starting from %s\n' "$start"
    printf 'Searched for these rule-details directories at every parent:\n'
    local rel
    for rel in "${RULE_DETAILS_PATHS[@]}"; do
      printf '  - %s\n' "$rel"
    done
  } >&2
  return 1
}

# ---------------------------------------------------------------------------
# Source-file discovery and validation
# ---------------------------------------------------------------------------

# Mandatory source files (paths relative to <DOCS-ROOT>).
MANDATORY_SOURCES=(
  "aidlc-docs/inception/requirements/requirements.md"
  "aidlc-docs/inception/application-design/application-design.md"
)

# Optional source files (paths relative to <DOCS-ROOT>). Order is preserved
# in the manifest's published_files list.
OPTIONAL_SOURCES=(
  "aidlc-docs/inception/application-design/components.md"
  "aidlc-docs/inception/application-design/component-methods.md"
  "aidlc-docs/inception/application-design/services.md"
)

# check_mandatory_sources <docs-root>
# Returns 0 if all mandatory files exist. Returns 1 and prints the list of
# missing files to stderr otherwise.
check_mandatory_sources() {
  local docs_root="$1"
  local missing=()
  local rel
  for rel in "${MANDATORY_SOURCES[@]}"; do
    if [[ ! -f "$docs_root/$rel" ]]; then
      missing+=("$rel")
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    {
      printf 'Missing mandatory source file(s) under %s:\n' "$docs_root"
      local m
      for m in "${missing[@]}"; do
        printf '  - %s\n' "$m"
      done
      printf '\nThese files are produced by the AIDLC inception flow.\n'
      printf 'Run inception to completion before publishing.\n'
    } >&2
    return 1
  fi
  return 0
}

# discover_optional_sources <docs-root>
# Echoes one line per *present* optional source file (relative path) on
# stdout, and prints a Found/Skipping report to stderr. Always returns 0.
discover_optional_sources() {
  local docs_root="$1"
  local found=()
  local skipped=()
  local rel
  for rel in "${OPTIONAL_SOURCES[@]}"; do
    if [[ -f "$docs_root/$rel" ]]; then
      found+=("$rel")
    else
      skipped+=("$rel")
    fi
  done

  {
    if [[ ${#found[@]} -gt 0 ]]; then
      printf 'Found optional source(s):\n'
      local f
      for f in "${found[@]}"; do
        printf '  + %s\n' "$f"
      done
    else
      printf 'No optional sources found.\n'
    fi
    if [[ ${#skipped[@]} -gt 0 ]]; then
      printf 'Skipping (not present):\n'
      local s
      for s in "${skipped[@]}"; do
        printf '  - %s\n' "$s"
      done
    fi
  } >&2

  local f
  for f in "${found[@]}"; do
    printf '%s\n' "$f"
  done
  return 0
}

# ---------------------------------------------------------------------------
# Branch warning and overwrite prompt
# ---------------------------------------------------------------------------

# current_branch
# Echoes the current git branch on stdout, or empty string if not in a git
# repo. Always returns 0. Tests override via PUBLISH_ARTIFACTS_BRANCH_OVERRIDE.
current_branch() {
  if [[ -n "${PUBLISH_ARTIFACTS_BRANCH_OVERRIDE:-}" ]]; then
    printf '%s' "$PUBLISH_ARTIFACTS_BRANCH_OVERRIDE"
    return 0
  fi
  git rev-parse --abbrev-ref HEAD 2>/dev/null || true
}

# warn_if_main
# If the current branch is "main" or "master", warns and prompts on stdin.
# Returns 0 on confirm-or-not-on-main; 1 if the user declines.
warn_if_main() {
  local branch
  branch="$(current_branch)"
  if [[ -z "$branch" ]]; then
    return 0
  fi
  if [[ "$branch" != "main" && "$branch" != "master" ]]; then
    return 0
  fi
  {
    printf '\nWARNING: You are on branch "%s".\n' "$branch"
    printf 'Publishing typically happens FROM a feature branch and the\n'
    printf 'resulting docs are then committed via PR onto main.\n'
    printf 'Continuing here will write generated-docs/ on the main branch\n'
    printf 'directly, which is usually not what you want.\n'
  } >&2
  printf 'Continue anyway? [y/N]: ' >&2
  local reply
  if ! IFS= read -r reply; then
    return 1
  fi
  case "$reply" in
    y|Y|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

# prompt_overwrite <target-dir>
# If the target dir exists, prompts and returns 0 only on y/Y.
# If the target does not exist, returns 0 silently.
prompt_overwrite() {
  local target="$1"
  if [[ ! -e "$target" ]]; then
    return 0
  fi
  printf '\nTarget directory already exists: %s\n' "$target" >&2
  printf 'Overwrite? [y/N]: ' >&2
  local reply
  if ! IFS= read -r reply; then
    return 1
  fi
  case "$reply" in
    y|Y|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

# ---------------------------------------------------------------------------
# File copy and manifest generation
# ---------------------------------------------------------------------------

# Output layout under <DOCS-ROOT>/generated-docs/artifacts/<artifact-name>/:
#   manifest.yaml
#   requirements.md                              <- inception/requirements/
#   application-design/application-design.md    <- inception/application-design/
#   application-design/components.md             <- if present
#   application-design/component-methods.md      <- if present
#   application-design/services.md               <- if present

# _target_path_for_source <source-rel-path>
# Maps a source path under aidlc-docs/inception/... to the corresponding
# output path under generated-docs/artifacts/<name>/.
_target_path_for_source() {
  local rel="$1"
  case "$rel" in
    aidlc-docs/inception/requirements/requirements.md)
      printf 'requirements.md' ;;
    aidlc-docs/inception/application-design/application-design.md)
      printf 'application-design/application-design.md' ;;
    aidlc-docs/inception/application-design/components.md)
      printf 'application-design/components.md' ;;
    aidlc-docs/inception/application-design/component-methods.md)
      printf 'application-design/component-methods.md' ;;
    aidlc-docs/inception/application-design/services.md)
      printf 'application-design/services.md' ;;
    *)
      printf 'unknown/%s' "$(basename "$rel")" ;;
  esac
}

# copy_files <docs-root> <artifact-name> <newline-separated-source-paths>
# Wipes the target directory then copies each source. Echoes the relative
# output paths (one per line) on stdout for the manifest.
copy_files() {
  local docs_root="$1"
  local artifact="$2"
  local sources="$3"

  local target_root="$docs_root/generated-docs/artifacts/$artifact"
  rm -rf "$target_root"
  mkdir -p "$target_root/application-design"

  local rel
  while IFS= read -r rel; do
    [[ -z "$rel" ]] && continue
    local target_rel
    target_rel="$(_target_path_for_source "$rel")"
    local target_abs="$target_root/$target_rel"
    mkdir -p "$(dirname "$target_abs")"
    cp "$docs_root/$rel" "$target_abs"
    printf '%s\n' "$target_rel"
  done <<< "$sources"
}

# git_branch_or_unknown
git_branch_or_unknown() {
  local b
  b="$(current_branch)"
  if [[ -z "$b" ]]; then
    printf 'unknown'
  else
    printf '%s' "$b"
  fi
}

# git_sha_or_unknown
git_sha_or_unknown() {
  if [[ -n "${PUBLISH_ARTIFACTS_SHA_OVERRIDE:-}" ]]; then
    printf '%s' "$PUBLISH_ARTIFACTS_SHA_OVERRIDE"
    return 0
  fi
  local s
  s="$(git rev-parse HEAD 2>/dev/null || true)"
  if [[ -z "$s" ]]; then
    printf 'unknown'
  else
    printf '%s' "$s"
  fi
}

# git_remote_or_unknown
# Returns the basename of the origin remote URL with .git stripped.
git_remote_or_unknown() {
  if [[ -n "${PUBLISH_ARTIFACTS_REMOTE_OVERRIDE:-}" ]]; then
    printf '%s' "$PUBLISH_ARTIFACTS_REMOTE_OVERRIDE"
    return 0
  fi
  local url
  url="$(git remote get-url origin 2>/dev/null || true)"
  if [[ -z "$url" ]]; then
    printf 'unknown'
    return 0
  fi
  local base
  base="$(basename "$url")"
  base="${base%.git}"
  printf '%s' "$base"
}

# write_manifest <target-root> <artifact-name> <newline-separated-published-files>
write_manifest() {
  local target_root="$1"
  local artifact="$2"
  local published="$3"

  local published_at branch sha remote
  published_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  branch="$(git_branch_or_unknown)"
  sha="$(git_sha_or_unknown)"
  remote="$(git_remote_or_unknown)"

  local manifest="$target_root/manifest.yaml"
  {
    printf 'artifact: %s\n' "$artifact"
    printf 'published_at: %s\n' "$published_at"
    printf 'publish_method: shell\n'
    printf 'source:\n'
    printf '  branch: %s\n' "$branch"
    printf '  sha: %s\n' "$sha"
    printf '  central_repo: %s\n' "$remote"
    printf 'published_files:\n'
    local f
    while IFS= read -r f; do
      [[ -z "$f" ]] && continue
      printf '  - %s\n' "$f"
    done <<< "$published"
  } > "$manifest"
}

# ---------------------------------------------------------------------------
# Main entry point
# ---------------------------------------------------------------------------
main() {
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  local docs_root
  if ! docs_root="$(resolve_docs_root "$script_dir")"; then
    exit 1
  fi
  printf 'Resolved <DOCS-ROOT>: %s\n' "$docs_root"

  if ! check_mandatory_sources "$docs_root"; then
    exit 1
  fi

  local optionals
  optionals="$(discover_optional_sources "$docs_root")"

  local artifact_name
  artifact_name="$(prompt_artifact_name)" || exit 1

  if ! warn_if_main; then
    printf 'Aborted by user.\n' >&2
    exit 1
  fi

  local target_root="$docs_root/generated-docs/artifacts/$artifact_name"
  if ! prompt_overwrite "$target_root"; then
    printf 'Aborted by user.\n' >&2
    exit 1
  fi

  # Build the full source list: mandatory first, then any discovered optionals.
  local sources=""
  local rel
  for rel in "${MANDATORY_SOURCES[@]}"; do
    sources+="$rel"$'\n'
  done
  if [[ -n "$optionals" ]]; then
    sources+="$optionals"$'\n'
  fi
  # Strip trailing newline.
  sources="${sources%$'\n'}"

  local published
  published="$(copy_files "$docs_root" "$artifact_name" "$sources")"
  write_manifest "$target_root" "$artifact_name" "$published"

  printf '\n\033[32mPublished:\033[0m %s\n' "$target_root"
  printf 'Files written:\n'
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    printf '  - %s\n' "$f"
  done <<< "$published"
  printf '  - manifest.yaml\n'
  printf '\nNext steps: review the diff, commit, and raise a PR onto main.\n'
}

# Run main only when executed directly, not when sourced by tests.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
