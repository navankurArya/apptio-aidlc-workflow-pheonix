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

## Publishing AIDLC artifacts to your fork's `main`

After you finish AIDLC inception on a feature branch, you can promote the
durable subset of generated docs (requirements + application design) into
`generated-docs/artifacts/<artifact-name>/` so they can be merged onto your
fork's `main` via PR. That folder becomes the long-term artifact record for
your team.

There are two interchangeable ways to publish — both produce the same
five-file output layout. The only structural difference is the
`publish_method` field in the per-artifact `manifest.yaml`.

### Path A — Shell script (mechanical)

```bash
./scripts/publish-artifacts.sh
```

Prompts for an artifact name, normalizes it to lowercase kebab-case, copies
the source files verbatim, and writes a manifest. Pure bash + git, no
external dependencies. Fast, deterministic, and reproducible without an
LLM. See [`scripts/README.md`](scripts/README.md) for full details.

### Path B — LLM-curated (Kiro)

In a Kiro session opened on this fork, say:

```
publish artifacts
```

(or `publish artifacts <name>` to skip the name prompt.) The steering file at
`.kiro/steering/aws-aidlc-rules/publish-artifacts.md` directs the LLM to
follow [`docs/publish-artifacts-llm-playbook.md`](docs/publish-artifacts-llm-playbook.md)
exactly. The output is the same five-file layout, but each file gets *light
prose curation* — AIDLC-process scaffolding (audit-trail references,
plan-file pointers, workflow-state language) is stripped, obvious filler
is tightened, and the manifest records `publish_method: llm-curated` with
the model name and date.

### Output layout

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

### When to use which

- Use **Path A** when you want a guaranteed, byte-for-byte copy of the
  inception docs, no LLM in the loop, and the fastest possible turnaround.
- Use **Path B** when you want the published docs tightened up for product-
  repo reviewers who do not need to see AIDLC's internal workflow chatter.

Both paths are safe to re-run on the same feature branch — re-running will
prompt before overwriting an existing target folder.

## Repo layout

```
aidlc-workflow/
├── .kiro/                      # Kiro IDE / CLI steering content
│   ├── steering/aws-aidlc-rules/        # core-workflow.md, publish-artifacts.md
│   └── aws-aidlc-rule-details/
│       ├── common/             # process-overview, session-continuity, ...
│       ├── inception/          # workspace-detection, requirements-analysis, ...
│       ├── construction/       # functional-design, code-generation, ...
│       ├── operations/         # operations.md (placeholder)
│       └── extensions/         # security/baseline/, testing/property-based/
├── .bob/                       # Mirror for the Bob/AI-assisted setup
├── scripts/                    # publish-artifacts.sh + tests/
├── docs/                       # publish-artifacts-llm-playbook.md
├── .gitignore
├── README.md                   # this file
├── CONTRIBUTING.md             # scope, branching, customization, release process
├── CHANGELOG.md                # per-version human-readable notes
├── manifest.yaml               # single source of truth: version + compatibility
└── CODEOWNERS                  # central-team ownership over steering paths
```

## Contributing

See **[CONTRIBUTING.md](CONTRIBUTING.md)**. In particular, read the **"Contributing back from a fork"** section before opening your first PR — branching from your fork's `main` will produce a polluted diff. Always branch from `upstream/main`.
