# Publish Artifacts — LLM-curated playbook

**Audience:** an LLM (Kiro, Claude, etc.) acting on a user's request to publish
AIDLC inception docs to the team's central fork. This file is the canonical
behaviour spec.

**Companion:** `scripts/publish-artifacts.sh` does the same job mechanically
(no curation). This playbook produces the same `generated-docs/artifacts/<artifact-name>/`
output layout, with light prose curation applied to remove AIDLC-process
scaffolding before the docs land on the team's `main` branch.

---

## Purpose

Produce the same `<DOCS-ROOT>/generated-docs/artifacts/<artifact-name>/` output
that `scripts/publish-artifacts.sh` produces, but with **light prose curation**
of the source files so the published docs read cleanly to a product-repo
reviewer who does not need to see AIDLC's internal workflow scaffolding.

The shell script and this playbook are interchangeable from a reader's
perspective. The only structural difference is the manifest's
`publish_method` field (`shell` vs. `llm-curated`) and an additional
`curated_by` block recording which model curated the output.

---

## Trigger phrases

Run this playbook when the user says any of:

- `publish artifacts`
- `publish artifacts <name>`
- `publish the <name> artifact`
- `curate and publish artifacts`
- `LLM publish artifacts` or `LLM publish artifacts <name>`

If the trigger is ambiguous (e.g. the user says "publish" with no further
context while AIDLC inception docs exist), confirm the intent before acting.

---

## Step-by-step instructions

Follow these steps in order. Do not reorder them. Do not skip any step.

### 1. Get the artifact name

If the user supplied a name in the trigger phrase, use it. Otherwise ask:

> Artifact name? (e.g. "labels" or "Bulk Label Assignment")

### 2. Normalize the artifact name

Apply these rules in order:

1. Lowercase the entire string.
2. Trim leading and trailing whitespace.
3. Replace any run of whitespace with a single dash (`-`).
4. Collapse repeated dashes.
5. Strip leading and trailing dashes.

Validate the result against the regex `^[a-z0-9]+(-[a-z0-9]+)*$`. If validation
fails, show the user the normalized form and ask them to retype:

> The normalized name is "labels--v2", which is not a valid kebab-case
> identifier. Names must be lowercase letters, digits, and single dashes.
> Please retype the artifact name.

### 3. Resolve `<DOCS-ROOT>`

Walk up from the working directory looking for any of these rule-details
directories, **in this priority order**:

1. `.aidlc/aidlc-rules/aws-aidlc-rule-details/`
2. `.aidlc-rule-details/`
3. `.kiro/aws-aidlc-rule-details/`
4. `.amazonq/aws-aidlc-rule-details/`

The folder containing the **first match** is `<DOCS-ROOT>`. If none of the
four exist anywhere up the tree, abort and tell the user that `<DOCS-ROOT>`
could not be resolved.

### 4. Verify mandatory source files

These two files **must** exist under `<DOCS-ROOT>`:

- `aidlc-docs/inception/requirements/requirements.md`
- `aidlc-docs/inception/application-design/application-design.md`

If either is missing, abort with a clear message naming the missing file(s)
and remind the user that AIDLC inception must be run to completion before
publishing.

### 5. List optional source files

Check which of these are present (skip silently if absent):

- `aidlc-docs/inception/application-design/components.md`
- `aidlc-docs/inception/application-design/component-methods.md`
- `aidlc-docs/inception/application-design/services.md`

Print a `Found:` and `Skipping:` report so the user sees exactly what is
being published.

### 6. Warn if on main/master

Run `git rev-parse --abbrev-ref HEAD`. If the result is `main` or `master`,
print a warning:

> WARNING: You are on branch "main". Publishing typically happens FROM a
> feature branch and the resulting docs are then committed via PR onto
> main. Continuing here will write generated-docs/ on main directly.
> Continue anyway? [y/N]

Abort on `n` or empty.

### 7. Confirm overwrite

If `<DOCS-ROOT>/generated-docs/artifacts/<artifact-name>/` already exists,
ask:

> Target directory already exists: <path>. Overwrite? [y/N]

Abort on `n` or empty.

### 8. Apply light curation to each source file

This is the only step where the LLM path differs from the shell path. For
**each** file (mandatory or optional) you are about to publish:

#### What to remove (AIDLC-process noise)

- Audit-trail references like `(see audit.md)`, `(logged in audit.md)`.
- Plan-file pointers like `(see plans/...)`, `(refer to plans/execution-plan.md)`.
- Workflow-state language: `Phase complete`, `Stage approved`, `Continue to
  Next Stage`, `Awaiting user approval`.
- References to `aidlc-state.md`, `requirement-verification-questions.md`,
  `application-design-plan.md`, or other internal AIDLC scaffolding files.
- Inception-stage chatter: `Per the depth assessment...`, `Following the
  intent analysis above...`.

#### What to tighten

- Obvious filler prose that adds no information ("It should be noted that...",
  "It is worth mentioning that...").
- Redundant sentences that re-state the section heading.

#### What to fix

- Sections marked `TBD` when the answer appears verbatim elsewhere in the
  same file. Replace `TBD` with the answer.
- Internal contradictions where one section says X and another says X' for
  the same fact. Pick the one that matches the most recent / most specific
  context and align the other.

#### What to **NEVER** do

- Do **not** invent content not in the source. If something is genuinely
  missing, leave it missing.
- Do **not** restructure or reorder sections.
- Do **not** merge files (e.g. fold `services.md` into `application-design.md`).
- Do **not** drop sections, even ones that look like AIDLC scaffolding —
  curate the prose inside them, but keep the heading.
- Do **not** change code blocks, diagrams (Mermaid, ASCII), tables, or any
  factual content (numbers, identifiers, API paths, schemas).
- Do **not** translate or rephrase technical terms.

### 9. Write the output layout

Write the curated content into the same five-file layout as the shell
script, under `<DOCS-ROOT>/generated-docs/artifacts/<artifact-name>/`:

```
generated-docs/artifacts/<artifact-name>/
├── manifest.yaml
├── requirements.md
└── application-design/
    ├── application-design.md
    ├── components.md          (if present in source)
    ├── component-methods.md   (if present in source)
    └── services.md            (if present in source)
```

If the target folder already exists (and the user confirmed overwrite in
step 7), wipe it before writing — the published set is the new source of
truth.

### 10. Write the manifest

Write `manifest.yaml` with this exact schema. The `publish_method` and
`curated_by` fields are what distinguish an LLM-curated publish from the
shell-script publish.

```yaml
artifact: <artifact-name>
published_at: <ISO-8601 UTC timestamp, e.g. 2026-06-14T11:42:53Z>
publish_method: llm-curated
curated_by:
  model: <your model name, e.g. claude-sonnet-4-5 or kiro-default>
  date: <ISO-8601 date, e.g. 2026-06-14>
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

The `published_files` list MUST list only files actually written. Use the
declared order (requirements first, then application-design subfolder
alphabetically by source order: application-design, components,
component-methods, services).

If any `git` call fails (no repo, no remote), record `unknown` for that
field instead of failing.

### 11. Print a summary

Tell the user:

- Where the output was written.
- Which files were published.
- That the manifest records `publish_method: llm-curated`.
- Reminder: review the diff (`git diff` against the previous published
  version, if any) before committing and raising a PR onto `main`.

---

## Worked before/after example

The following snippets are short illustrations of what "light curation"
looks like. Both come from `aidlc-docs/inception/requirements/requirements.md`.

### Before (raw inception output)

```markdown
## 1. Intent Analysis Summary

- **Source**: PDF — *Report Labels/ Tags* (Tags-050526-073735), supplemented
  by answers to `requirement-verification-questions.md` (v2 — updated answers).
- **User Request**: Deliver a label/tag capability so users can organize,
  categorise, and discover reports more effectively...

Per the depth assessment captured in `plans/execution-plan.md`, this artifact
is being treated as Comprehensive depth. The detailed traceability matrix
is logged in audit.md and will be revisited at Stage approval.
```

### After (curated)

```markdown
## 1. Intent Analysis Summary

- **Source**: PDF — *Report Labels/ Tags* (Tags-050526-073735).
- **User Request**: Deliver a label/tag capability so users can organize,
  categorise, and discover reports more effectively...

This artifact is treated as Comprehensive depth, with a full traceability
matrix.
```

### What changed

- Removed: `requirement-verification-questions.md (v2 — updated answers)`
  reference (AIDLC scaffolding).
- Removed: `Per the depth assessment captured in plans/execution-plan.md`
  (plan-file pointer).
- Removed: `is logged in audit.md and will be revisited at Stage approval`
  (audit + workflow-state language).
- Preserved: heading, source citation, user request quote, depth label,
  fact that traceability exists.

### What was NOT changed

- The PDF source citation stayed identical, including the timestamp.
- The user-request prose was preserved verbatim.
- The depth label ("Comprehensive") was not rewritten.

---

## Manual verification checklist

Before telling the user the publish is complete, the LLM (or the human
reviewing the LLM's output) should confirm:

- [ ] Every section heading from each source file appears in the
      corresponding output file.
- [ ] No new sections or headings were invented.
- [ ] Every code block, diagram, and table from the source survives in the
      output unchanged.
- [ ] No factual values changed (numbers, identifiers, API paths, schemas).
- [ ] `manifest.yaml` has `publish_method: llm-curated` and a populated
      `curated_by` block.
- [ ] `manifest.yaml`'s `published_files` list matches what is actually on
      disk under the artifact folder.
- [ ] File layout matches `scripts/publish-artifacts.sh`'s output exactly:
      `requirements.md` at the top, the rest under `application-design/`.

If any item is unchecked, fix the output before reporting completion.
