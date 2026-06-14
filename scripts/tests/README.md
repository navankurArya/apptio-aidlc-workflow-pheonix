# Tests for `publish-artifacts.sh`

## Running

```bash
./scripts/tests/run-tests.sh
```

No dependencies beyond `bash` and the standard POSIX tools (`mktemp`, `cp`,
`mkdir`, `rm`). No external test framework — the runner provides its own
`assert_eq` / `assert_contains` / `assert_exit_code` / `assert_file_exists`
helpers.

## Conventions

- Each test file is named `test-<topic>.sh` and lives in this directory.
- Each test function is named `test_<something>` and is auto-discovered by
  `run-tests.sh`.
- Tests run in subshells, so they cannot pollute outer state with `cd`,
  `set`, exported vars, or trap installs.
- A test signals failure by `return 1` (or by letting an `assert_*` helper
  return non-zero and then `return 1`). A test signals success by
  `return 0`.
- Tests that need fixtures use `mktemp -d` and clean up via `trap`.

## Adding a new test

1. Create `scripts/tests/test-<topic>.sh`.
2. Define one or more `test_<something>` functions in it.
3. Run `./scripts/tests/run-tests.sh` and watch them get picked up.
