# aidlc-workflow

The organization's source of truth for AI-DLC steering files, rule details, hooks, and skills.

This repo hosts the common workflow content used by all pilot teams. Teams **fork** this repo, work on their own `main` and feature branches, and pull updates manually when they want them.

## Purpose

A single, versioned, governed home for:

- AI-DLC core workflow rules (`.kiro/steering/aws-aidlc-rules/`, mirrored under `.bob/`)
- Phase-specific rule details: `inception/`, `construction/`, `operations/`
- Common rules: process overview, session continuity, content validation, question format, terminology, error handling, depth levels, ASCII diagram standards, overconfidence prevention, welcome message, workflow changes
- Extensions (opt-in): `security/baseline/`, `testing/property-based/`

## How to upgrade

You have two options. Both are documented in [CONTRIBUTING.md](CONTRIBUTING.md); the short forms are:

### Option A — Track the latest `main`

```
git fetch upstream
git checkout main
git merge upstream/main
```

Read [CHANGELOG.md](CHANGELOG.md) before merging so you know what changed.

### Option B — Pin to a specific version tag

```
git fetch upstream --tags
git merge v1.0.0   # replace with the tag you want
```

Pinning is supported and recommended if your team needs to stay on a known-good version while the org ships newer releases.

## Versioning

Releases follow [Semantic Versioning](https://semver.org/) using git tags (e.g., `v1.0.0`):

- **MAJOR** — Breaking changes to rule semantics, removed rules, or directory restructuring that consumers reference.
- **MINOR** — New rules, new extensions, new opt-in files, additive content.
- **PATCH** — Wording fixes, typo corrections, clarifications without semantic change.

The current version, release date, shipped paths, and compatibility metadata live in **[`manifest.yaml`](manifest.yaml)** — this is the single source of truth for version. There is no separate `VERSION` file.

Per-release human-readable notes live in **[`CHANGELOG.md`](CHANGELOG.md)**.

## Customization model (summary)

- **No upstream PR needed:** Files added under `extensions/<team-or-domain>/` in your fork. Teams own these.
- **Requires upstream PR:** Any change to `common/`, `inception/`, `construction/`, `operations/`, the core workflow file (`core-workflow.md`), or root governance files (`README.md`, `CHANGELOG.md`, `CONTRIBUTING.md`, `manifest.yaml`, `CODEOWNERS`, `.gitignore`).

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full customization rules and the upstream-branching workflow that keeps PR diffs clean.

## Multi-folder workspace usage

Pilot teams typically open this fork **alongside** one or more application repos as a multi-folder IDE workspace. In that layout the workflow recognises two roots:

- `<DOCS-ROOT>` — the folder hosting `.kiro/aws-aidlc-rule-details/` (this fork). All AI-DLC documentation under `aidlc-docs/` is generated here, so every team's docs sit in a consistent location across pilots.
- `<WORKSPACE-ROOT>` — the application repo(s) opened next to this fork. Generated code, build files, and tests land there.

If only this fork is open, both roots collapse to the same folder and the behaviour is identical to single-folder use. See `common/terminology.md` and `inception/workspace-detection.md` in the rule details for the full resolution rules.

## Repo layout

```
aidlc-workflow/
├── .kiro/                      # Kiro IDE / CLI steering content
│   ├── steering/aws-aidlc-rules/        # core-workflow.md
│   └── aws-aidlc-rule-details/
│       ├── common/             # process-overview, session-continuity, ...
│       ├── inception/          # workspace-detection, requirements-analysis, ...
│       ├── construction/       # functional-design, code-generation, ...
│       ├── operations/         # operations.md (placeholder)
│       └── extensions/         # security/baseline/, testing/property-based/
├── .bob/                       # Mirror for the Bob/AI-assisted setup
├── .gitignore
├── README.md                   # this file
├── CONTRIBUTING.md             # scope, branching, customization, release process
├── CHANGELOG.md                # per-version human-readable notes
├── manifest.yaml               # single source of truth: version + compatibility
└── CODEOWNERS                  # central-team ownership over steering paths
```

## Contributing

See **[CONTRIBUTING.md](CONTRIBUTING.md)**. In particular, read the **"Contributing back from a fork"** section before opening your first PR — branching from your fork's `main` will produce a polluted diff. Always branch from `upstream/main`.
