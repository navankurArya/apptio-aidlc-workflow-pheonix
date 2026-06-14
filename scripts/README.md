# `scripts/publish-artifacts.sh`

Promotes AIDLC inception docs from a feature branch into
`<DOCS-ROOT>/generated-docs/artifacts/<artifact-name>/` so the team can raise
a PR onto their fork's `main` branch.

This is the **mechanical** path. For LLM-curated publishing (same output,
with light prose curation), say "publish artifacts [<name>]" in Kiro and the
steering rule at `.kiro/steering/aws-aidlc-rules/publish-artifacts.md` will
take over.

## Usage

```bash
./scripts/publish-artifacts.sh
```

The script will:

1. Resolve `<DOCS-ROOT>` by walking up looking for any of
   `.aidlc/aidlc-rules/aws-aidlc-rule-details/`, `.aidlc-rule-details/`,
   `.kiro/aws-aidlc-rule-details/`, `.amazonq/aws-aidlc-rule-details/`.
2. Verify the two **mandatory** source files exist:
   - `aidlc-docs/inception/requirements/requirements.md`
   - `aidlc-docs/inception/application-design/application-design.md`
3. Detect which **optional** source files are present:
   - `aidlc-docs/inception/application-design/components.md`
   - `aidlc-docs/inception/application-design/component-methods.md`
   - `aidlc-docs/inception/application-design/services.md`
4. Prompt for an artifact name; normalize to lowercase kebab-case
   (e.g. `"Bulk Label Assignment"` → `bulk-label-assignment`); validate
   against `^[a-z0-9]+(-[a-z0-9]+)*$` and re-prompt on failure.
5. Warn if the current branch is `main` or `master`.
6. Prompt before overwriting an existing target folder.
7. Copy the discovered files into the output layout (see below).
8. Write `manifest.yaml`.

## Output layout

```
<DOCS-ROOT>/generated-docs/artifacts/<artifact-name>/
├── manifest.yaml
├── requirements.md
└── application-design/
    ├── application-design.md
    ├── components.md          (if present in source)
    ├── component-methods.md   (if present in source)
    └── services.md            (if present in source)
```

## Manifest schema

```yaml
artifact: <artifact-name>
published_at: <ISO-8601 UTC timestamp>
publish_method: shell
source:
  branch: <output of: git rev-parse --abbrev-ref HEAD>
  sha: <output of: git rev-parse HEAD>
  central_repo: <basename of: git remote get-url origin, with .git stripped>
published_files:
  - requirements.md
  - application-design/application-design.md
  - application-design/components.md           # only if published
  - application-design/component-methods.md    # only if published
  - application-design/services.md             # only if published
```

If any `git` call fails (no repo, no remote), the corresponding field is
recorded as `unknown`.

The LLM-curated path produces an additional `curated_by` block:

```yaml
publish_method: llm-curated
curated_by:
  model: <model name>
  date: <ISO-8601 date>
```

## Exit codes

| Code | Meaning |
| ---- | ------- |
| `0`  | Successful publish. |
| `1`  | `<DOCS-ROOT>` could not be resolved, a mandatory source is missing, the user declined the branch warning, the user declined the overwrite prompt, or the user closed stdin during the artifact-name prompt. |

## Tests

```bash
./scripts/tests/run-tests.sh
```

Pure bash, no external dependencies. Add new tests by creating
`scripts/tests/test-<topic>.sh` and defining functions named `test_<something>` —
the runner discovers them automatically. See `scripts/tests/README.md` for
conventions.

## Test-only environment overrides

These exist purely to make functions like `warn_if_main` and `write_manifest`
deterministic in tests; do not set them when running the script for real.

| Variable | Effect |
| -------- | ------ |
| `PUBLISH_ARTIFACTS_BRANCH_OVERRIDE` | Returns this value instead of `git rev-parse --abbrev-ref HEAD`. Used to simulate `main`, `master`, or a feature branch in tests. |
| `PUBLISH_ARTIFACTS_SHA_OVERRIDE`    | Returns this value instead of `git rev-parse HEAD`. |
| `PUBLISH_ARTIFACTS_REMOTE_OVERRIDE` | Returns this value instead of `git remote get-url origin`. |
