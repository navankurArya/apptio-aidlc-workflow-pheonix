# Publish Artifacts steering rule

**Trigger:** When the user says any of the following, follow
`docs/publish-artifacts-llm-playbook.md` (relative to `<DOCS-ROOT>`) **exactly**:

- `publish artifacts`
- `publish artifacts <name>`
- `publish the <name> artifact`
- `curate and publish artifacts`
- `LLM publish artifacts` or `LLM publish artifacts <name>`

**Behaviour:** Do not deviate from the steps or the curation rules in the
playbook. Specifically:

- Apply only the *light curation* rules described in playbook step 8.
- Do not invent content, restructure sections, merge files, or drop
  headings.
- Always write `manifest.yaml` with `publish_method: llm-curated` and a
  populated `curated_by` block (model name + ISO-8601 date).
- Always confirm with the user before overwriting an existing
  `<DOCS-ROOT>/generated-docs/artifacts/<artifact-name>/` folder.

**Companion path:** Teams that prefer a mechanical (no-curation) publish
should run `./scripts/publish-artifacts.sh` instead. Both produce the same
five-file output layout; the `publish_method` field in the manifest
distinguishes them.

**Reference:** The full playbook is at `docs/publish-artifacts-llm-playbook.md`.
Read it before acting on any of the trigger phrases above.
