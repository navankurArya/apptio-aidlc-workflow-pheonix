#!/usr/bin/env bash
# Pure-bash test runner for scripts/publish-artifacts.sh.
#
# Discovers every scripts/tests/test-*.sh file, sources it, then runs every
# function in the sourced file whose name starts with "test_". Tracks pass/fail
# counts and exits non-zero if any test fails.
#
# No external dependencies — runs anywhere bash runs.
#
# Usage:   ./scripts/tests/run-tests.sh
# Add tests by creating scripts/tests/test-<topic>.sh and defining functions
# named test_<something>.

# Note: deliberately not using `set -e` — assertion failures must be allowed to
# return non-zero without aborting the whole run. We do use `set -u` to catch
# typos in test code.
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Globals updated by assertions and the runner.
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
CURRENT_TEST=""
CURRENT_TEST_FAILED=0
FAILURE_MESSAGES=()

# ---------------------------------------------------------------------------
# Assertion helpers — sourced into every test file.
# ---------------------------------------------------------------------------

# assert_eq <expected> <actual> [<message>]
assert_eq() {
  local expected="$1"
  local actual="$2"
  local message="${3:-}"
  if [[ "$expected" != "$actual" ]]; then
    CURRENT_TEST_FAILED=1
    local msg="  expected: '$expected'"$'\n'"  actual:   '$actual'"
    if [[ -n "$message" ]]; then
      msg="  $message"$'\n'"$msg"
    fi
    FAILURE_MESSAGES+=("$CURRENT_TEST"$'\n'"$msg")
    return 1
  fi
  return 0
}

# assert_contains <haystack> <needle> [<message>]
assert_contains() {
  local haystack="$1"
  local needle="$2"
  local message="${3:-}"
  if [[ "$haystack" != *"$needle"* ]]; then
    CURRENT_TEST_FAILED=1
    local msg="  expected to contain: '$needle'"$'\n'"  actual:              '$haystack'"
    if [[ -n "$message" ]]; then
      msg="  $message"$'\n'"$msg"
    fi
    FAILURE_MESSAGES+=("$CURRENT_TEST"$'\n'"$msg")
    return 1
  fi
  return 0
}

# assert_exit_code <expected_code> <actual_code> [<message>]
assert_exit_code() {
  local expected="$1"
  local actual="$2"
  local message="${3:-}"
  if [[ "$expected" != "$actual" ]]; then
    CURRENT_TEST_FAILED=1
    local msg="  expected exit code: $expected"$'\n'"  actual exit code:   $actual"
    if [[ -n "$message" ]]; then
      msg="  $message"$'\n'"$msg"
    fi
    FAILURE_MESSAGES+=("$CURRENT_TEST"$'\n'"$msg")
    return 1
  fi
  return 0
}

# assert_file_exists <path> [<message>]
assert_file_exists() {
  local path="$1"
  local message="${2:-}"
  if [[ ! -f "$path" ]]; then
    CURRENT_TEST_FAILED=1
    local msg="  expected file to exist: '$path'"
    if [[ -n "$message" ]]; then
      msg="  $message"$'\n'"$msg"
    fi
    FAILURE_MESSAGES+=("$CURRENT_TEST"$'\n'"$msg")
    return 1
  fi
  return 0
}

pass() {
  printf '  \033[32m✓\033[0m %s\n' "$CURRENT_TEST"
  TESTS_PASSED=$((TESTS_PASSED + 1))
}

fail() {
  printf '  \033[31m✗\033[0m %s\n' "$CURRENT_TEST"
  TESTS_FAILED=$((TESTS_FAILED + 1))
}

# ---------------------------------------------------------------------------
# Test discovery and execution.
# ---------------------------------------------------------------------------

# Run every function in the current shell whose name matches the given prefix.
# Defined here so each test file can rely on the same convention.
run_tests_in_file() {
  local file_path="$1"
  printf '\n\033[1m%s\033[0m\n' "$(basename "$file_path")"

  # Snapshot the set of test_* functions before sourcing this file, so we can
  # diff afterwards and run only the functions THIS file added. Without the
  # diff, every file would re-run every test_* function defined by any file
  # processed before it.
  local before_fns
  before_fns="$(compgen -A function | grep '^test_' || true)"

  # Source the test file. Functions defined inside become callable.
  # shellcheck disable=SC1090
  source "$file_path"

  local after_fns
  after_fns="$(compgen -A function | grep '^test_' || true)"

  # New functions = lines in after_fns not present in before_fns.
  local new_fns
  if [[ -z "$before_fns" ]]; then
    new_fns="$after_fns"
  else
    new_fns="$(comm -23 <(printf '%s\n' "$after_fns" | sort -u) \
                       <(printf '%s\n' "$before_fns" | sort -u))"
  fi

  if [[ -z "$new_fns" ]]; then
    printf '  (no test_* functions found in this file)\n'
    return 0
  fi

  local fn
  while IFS= read -r fn; do
    if [[ -n "$fn" && "$fn" == test_* ]]; then
      CURRENT_TEST="$fn"
      CURRENT_TEST_FAILED=0
      TESTS_RUN=$((TESTS_RUN + 1))

      # Run the test in a subshell so it cannot pollute outer state with
      # `cd`, `set`, exported vars, or trap installs. The subshell inherits
      # CURRENT_TEST_FAILED but cannot mutate it back into the parent — so we
      # check the subshell's exit code instead. Tests should `return 1` (or let
      # an assertion fail and then `return 1`) to signal failure. By convention
      # they `return 0` on success.
      local rc=0
      ( "$fn" ) || rc=$?

      if [[ $rc -eq 0 ]]; then
        pass
      else
        # The failure message was added inside the subshell, so we cannot see
        # FAILURE_MESSAGES here. Emit a generic failure note; individual
        # assertions print detail to stderr from inside the subshell.
        fail
      fi
    fi
  done <<< "$new_fns"
}

# Capture failure detail from inside subshells by patching assertion helpers
# to print to stderr immediately rather than relying on the array. This keeps
# error messages visible even though the subshell cannot mutate parent state.
assert_eq() {
  local expected="$1"
  local actual="$2"
  local message="${3:-}"
  if [[ "$expected" != "$actual" ]]; then
    {
      [[ -n "$message" ]] && printf '    %s\n' "$message"
      printf "    expected: '%s'\n" "$expected"
      printf "    actual:   '%s'\n" "$actual"
    } >&2
    return 1
  fi
  return 0
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local message="${3:-}"
  if [[ "$haystack" != *"$needle"* ]]; then
    {
      [[ -n "$message" ]] && printf '    %s\n' "$message"
      printf "    expected to contain: '%s'\n" "$needle"
      printf "    actual:              '%s'\n" "$haystack"
    } >&2
    return 1
  fi
  return 0
}

assert_exit_code() {
  local expected="$1"
  local actual="$2"
  local message="${3:-}"
  if [[ "$expected" != "$actual" ]]; then
    {
      [[ -n "$message" ]] && printf '    %s\n' "$message"
      printf '    expected exit code: %s\n' "$expected"
      printf '    actual exit code:   %s\n' "$actual"
    } >&2
    return 1
  fi
  return 0
}

assert_file_exists() {
  local path="$1"
  local message="${2:-}"
  if [[ ! -f "$path" ]]; then
    {
      [[ -n "$message" ]] && printf '    %s\n' "$message"
      printf "    expected file to exist: '%s'\n" "$path"
    } >&2
    return 1
  fi
  return 0
}

# ---------------------------------------------------------------------------
# Main loop.
# ---------------------------------------------------------------------------
main() {
  printf '\033[1mAIDLC publish-artifacts.sh test suite\033[0m\n'
  printf 'Repo root: %s\n' "$REPO_ROOT"

  shopt -s nullglob
  local test_files=("$SCRIPT_DIR"/test-*.sh)
  shopt -u nullglob

  if [[ ${#test_files[@]} -eq 0 ]]; then
    printf 'No test files found in %s\n' "$SCRIPT_DIR" >&2
    exit 1
  fi

  local f
  for f in "${test_files[@]}"; do
    run_tests_in_file "$f"
  done

  printf '\n\033[1mSummary:\033[0m %d run, \033[32m%d passed\033[0m, ' \
    "$TESTS_RUN" "$TESTS_PASSED"
  if [[ $TESTS_FAILED -gt 0 ]]; then
    printf '\033[31m%d failed\033[0m\n' "$TESTS_FAILED"
    exit 1
  else
    printf '%d failed\n' "$TESTS_FAILED"
    exit 0
  fi
}

main "$@"
