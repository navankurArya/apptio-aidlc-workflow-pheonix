# Changelog

All notable changes to `aidlc-workflow` are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

The current version, release date, shipped paths, and compatibility metadata live in [`manifest.yaml`](manifest.yaml). When adding entries here, also update the manifest if the change affects version, breaking changes, or deprecations (see [CONTRIBUTING.md](CONTRIBUTING.md)).

## [Unreleased]

### Added

- **Publish-artifacts tooling.** Two interchangeable paths for promoting
  AIDLC inception docs from a feature branch into
  `generated-docs/artifacts/<artifact-name>/` so teams can raise a PR onto
  their fork's `main`:
  - `scripts/publish-artifacts.sh` — pure bash + git mechanical publisher.
    Resolves `<DOCS-ROOT>` by walking up for `.aidlc/`, `.aidlc-rule-details/`,
    `.kiro/`, or `.amazonq/` rule-details directories; verifies mandatory
    sources (`requirements.md`, `application-design.md`); discovers optional
    sources (`components.md`, `component-methods.md`, `services.md`);
    normalizes the artifact name to lowercase kebab-case; warns when
    publishing from `main`/`master`; prompts before overwriting; copies
    files verbatim; writes `manifest.yaml` with `publish_method: shell`.
  - `docs/publish-artifacts-llm-playbook.md` — canonical behaviour spec for
    the LLM-curated path. Same five-file output layout, with light prose
    curation that strips AIDLC-process scaffolding (audit-trail references,
    plan-file pointers, workflow-state language) before the docs land on
    `main`. Manifest records `publish_method: llm-curated` plus a
    `curated_by` block (model name + ISO-8601 date).
  - `.kiro/steering/aws-aidlc-rules/publish-artifacts.md` (mirrored under
    `.bob/rules/aws-aidlc-rules/`) — Kiro/Bob steering rule that triggers
    the LLM playbook on phrases like `publish artifacts`,
    `publish artifacts <name>`, `publish the <name> artifact`,
    `curate and publish artifacts`, or `LLM publish artifacts`.
  - `scripts/tests/` — pure-bash test suite (`run-tests.sh` plus
    `test-smoke.sh`, `test-normalize.sh`, `test-prompts.sh`,
    `test-sources.sh`, `test-docs-root.sh`, `test-end-to-end.sh`) covering
    artifact-name normalization, validation, branch warning, overwrite
    prompts, source discovery, `<DOCS-ROOT>` resolution across all four
    rule-details layouts, and end-to-end copy + manifest generation.
  - `scripts/README.md` and `scripts/tests/README.md` — usage and
    test-conventions docs.
- README "Publishing AIDLC artifacts to your fork's `main`" section
  documenting both publish paths and the shared output layout.

### Changed

### Deprecated

### Removed

### Fixed

### Security

## [1.0.0] - 2026-06-03

Initial release. Establishes `aidlc-workflow` as the organization's source of truth for AI-DLC steering content, with versioning and governance scaffolding to support the fork-and-pull distribution model used by pilot teams.

### Added

#### Core workflow rule pack: `aws-aidlc-rules`

- `core-workflow.md` — adaptive AI-DLC workflow definition covering the inception, construction, and operations phases. Shipped at `.kiro/steering/aws-aidlc-rules/core-workflow.md` and mirrored under `.bob/rules/aws-aidlc-rules/`.

#### Common rules (`common/`)

Shipped at `.kiro/aws-aidlc-rule-details/common/` and mirrored under `.bob/aws-aidlc-rule-details/common/`:

- `process-overview.md` — workflow overview loaded at start of every session.
- `session-continuity.md` — session resumption guidance.
- `content-validation.md` — content validation requirements (Mermaid, ASCII art, escaping).
- `question-format-guide.md` — multiple-choice question formatting rules.
- `terminology.md` — shared vocabulary across phases.
- `error-handling.md` — error recovery and retry guidance.
- `depth-levels.md` — minimal / standard / comprehensive depth definitions.
- `ascii-diagram-standards.md` — ASCII diagram conventions.
- `overconfidence-prevention.md` — guardrails against overconfident model behavior.
- `welcome-message.md` — one-time welcome message displayed at workflow start.
- `workflow-changes.md` — process for proposing changes to the workflow itself.

#### Inception phase rules (`inception/`)

Shipped at `.kiro/aws-aidlc-rule-details/inception/` and mirrored under `.bob/`:

- `workspace-detection.md` — always-execute workspace and brownfield/greenfield detection.
- `reverse-engineering.md` — conditional brownfield reverse-engineering stage.
- `requirements-analysis.md` — adaptive-depth requirements analysis (always executes).
- `user-stories.md` — conditional user-stories stage with planning + generation parts.
- `workflow-planning.md` — always-execute workflow planning.
- `application-design.md` — conditional application-design stage.
- `units-generation.md` — conditional decomposition into units of work.

#### Construction phase rules (`construction/`)

Shipped at `.kiro/aws-aidlc-rule-details/construction/` and mirrored under `.bob/`:

- `functional-design.md` — conditional functional-design stage (per unit).
- `nfr-requirements.md` — conditional NFR requirements stage (per unit).
- `nfr-design.md` — conditional NFR design stage (per unit).
- `infrastructure-design.md` — conditional infrastructure-design stage (per unit).
- `code-generation.md` — always-execute code-generation stage (per unit, planning + generation parts).
- `build-and-test.md` — always-execute build-and-test stage after all units.

#### Operations phase rules (`operations/`)

Shipped at `.kiro/aws-aidlc-rule-details/operations/` and mirrored under `.bob/`:

- `operations.md` — placeholder for future deployment, monitoring, and incident-response workflows.

#### Extensions (opt-in) (`extensions/`)

Shipped at `.kiro/aws-aidlc-rule-details/extensions/` and mirrored under `.bob/`. Each extension provides a lightweight `*.opt-in.md` sentinel that the workflow surfaces during requirements analysis; the full rules file is loaded on-demand only when the user opts in:

- `security/baseline/` — `security-baseline.opt-in.md` and `security-baseline.md`.
- `testing/property-based/` — `property-based-testing.opt-in.md` and `property-based-testing.md`.

#### Governance scaffolding

- `README.md` — purpose, fork-and-pull consumption model, upgrade paths (latest and pinned), repo layout.
- `CONTRIBUTING.md` — scope rules, customization model, mandatory `upstream/main` branching workflow for clean PRs, versioning policy, release checklist, initial-setup prerequisites, branch-protection settings.
- `CHANGELOG.md` — this file; Keep-a-Changelog format.
- `manifest.yaml` — single source of truth for version and compatibility metadata. No separate `VERSION` file.
- `CODEOWNERS` — central-team ownership over `.kiro/`, `.bob/`, and root governance files.
- `.gitignore` — OS and editor hygiene.

[Unreleased]: ../../compare/v1.0.0...HEAD
[1.0.0]: ../../releases/tag/v1.0.0
