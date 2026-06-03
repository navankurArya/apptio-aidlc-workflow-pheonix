# Workspace Detection

**Purpose**: Resolve `<DOCS-ROOT>` and `<WORKSPACE-ROOT>(s)`, determine workspace state, and check for existing AI-DLC projects.

**Background**: AI-DLC supports two layouts:
- **Single-folder**: One workspace folder holds both the rule details and the application code. `<DOCS-ROOT>` and `<WORKSPACE-ROOT>` refer to the same folder.
- **Multi-folder**: One workspace folder hosts the rule details (the AI-DLC workflow repo); separate workspace folders hold application code. `<DOCS-ROOT>` is the rule-details folder; one or more other folders are `<WORKSPACE-ROOT>`s.

See `common/terminology.md` for the formal definitions.

## Step 1: Resolve `<DOCS-ROOT>`

1. The rule-details directory was already resolved by the core workflow loader (the first existing path among `.aidlc/aidlc-rules/aws-aidlc-rule-details/`, `.aidlc-rule-details/`, `.kiro/aws-aidlc-rule-details/`, `.amazonq/aws-aidlc-rule-details/`).
2. `<DOCS-ROOT>` is the workspace folder that contains that resolved rule-details directory.
3. All paths written as `aidlc-docs/...` in this rule set resolve to `<DOCS-ROOT>/aidlc-docs/...`.

**Record `<DOCS-ROOT>` for use in later steps. Do not write any files yet.**

## Step 2: Check for Existing AI-DLC Project

Check if `<DOCS-ROOT>/aidlc-docs/aidlc-state.md` exists:
- **If exists**: Resume from last phase (load context from previous phases). Read `Docs Root` and `Workspace Roots` from the existing state file and use them; do not re-detect.
- **If not exists**: Continue with new project assessment.

## Step 3: Identify Candidate Workspace Roots

Enumerate every workspace folder open in the IDE / agent session.

- The folder equal to `<DOCS-ROOT>` is the docs root.
- Every other open workspace folder is a candidate `<WORKSPACE-ROOT>` for application code.
- If only one folder is open (so `<DOCS-ROOT>` is the only candidate), treat it as both `<DOCS-ROOT>` and the sole `<WORKSPACE-ROOT>`.

## Step 4: Scan Each Candidate Workspace Root for Existing Code

For each candidate `<WORKSPACE-ROOT>`:
- Scan for source code files (.java, .py, .js, .ts, .jsx, .tsx, .kt, .kts, .scala, .groovy, .go, .rs, .rb, .php, .c, .h, .cpp, .hpp, .cc, .cs, .fs, etc.)
- Check for build files (pom.xml, package.json, build.gradle, Cargo.toml, go.mod, etc.)
- Look for project structure indicators
- Skip the `aidlc-docs/` directory if present
- Skip the `<DOCS-ROOT>` itself unless it is also the only candidate workspace root

**Record per-candidate findings:**
```markdown
## Candidate Workspace: [absolute path]
- **Existing Code**: [Yes/No]
- **Programming Languages**: [List if found]
- **Build System**: [Maven/Gradle/npm/etc. if found]
- **Project Structure**: [Monolith/Microservices/Library/Empty]
```

## Step 5: Select Active Workspace Root(s)

**Single candidate** (single-folder layout, or only one non-docs folder open):
- Use it as the sole `<WORKSPACE-ROOT>`. No prompt required.

**Multiple candidates** (multi-folder layout with more than one non-docs folder):
- Ask the user which workspace root(s) this run targets, using the standard multiple-choice question format from `common/question-format-guide.md`.
- Options: each candidate path, plus an "All of the above" option for runs that legitimately span multiple repos.
- Record the user's response in `audit.md`.
- If the user picks more than one, code generation must declare a target `<WORKSPACE-ROOT>` per unit (see `construction/code-generation.md`).

## Step 6: Determine Brownfield/Greenfield

- **Brownfield**: At least one selected `<WORKSPACE-ROOT>` contains existing application code.
- **Greenfield**: All selected `<WORKSPACE-ROOT>`s are empty of application code.

If brownfield, check for existing reverse engineering artifacts in `<DOCS-ROOT>/aidlc-docs/inception/reverse-engineering/`:
- **IF reverse engineering artifacts exist**:
    - Check if artifacts are stale (compare artifact timestamps against codebase's last significant modification across selected workspace roots).
    - **IF artifacts are current**: Load them, skip to Requirements Analysis.
    - **IF artifacts are stale**: Next phase is Reverse Engineering (rerun to refresh artifacts).
    - **IF user explicitly requests rerun**: Next phase is Reverse Engineering regardless of staleness.
- **IF no reverse engineering artifacts**: Next phase is Reverse Engineering.

## Step 7: Create Initial State File

Create `<DOCS-ROOT>/aidlc-docs/aidlc-state.md` (the literal path uses `aidlc-docs/aidlc-state.md` resolved against `<DOCS-ROOT>`):

```markdown
# AI-DLC State Tracking

## Project Information
- **Project Type**: [Greenfield/Brownfield]
- **Start Date**: [ISO timestamp]
- **Current Stage**: INCEPTION - Workspace Detection

## Roots
- **Docs Root**: [Absolute path to `<DOCS-ROOT>` — the folder hosting the AI-DLC rule details]
- **Workspace Roots**:
  - [Absolute path to first selected workspace root]
  - [Additional workspace roots, one per line, if multiple were selected]
- **Layout**: [Single-folder | Multi-folder]

## Workspace State
- **Existing Code**: [Yes/No across selected workspace roots]
- **Reverse Engineering Needed**: [Yes/No]
- **Per-Workspace Findings**:
  - `[workspace path]`: [Existing Code Yes/No, Languages, Build System]
  - [repeat per workspace root]

## Code Location Rules
- **Application Code**: A `<WORKSPACE-ROOT>` listed above (NEVER `<DOCS-ROOT>/aidlc-docs/`)
- **Documentation**: `<DOCS-ROOT>/aidlc-docs/` only
- **Structure patterns**: See code-generation.md Critical Rules

## Stage Progress
[Will be populated as workflow progresses]
```

## Step 8: Present Completion Message

**For Brownfield Projects:**
```markdown
# 🔍 Workspace Detection Complete

Workspace analysis findings:
• **Project Type**: Brownfield project
• **Layout**: [Single-folder | Multi-folder]
• **Docs Root**: `[absolute path]`
• **Workspace Root(s)**: `[list of selected workspace roots]`
• [AI-generated summary of workspace findings in bullet points]
• **Next Step**: Proceeding to **Reverse Engineering** to analyze existing codebase...
```

**For Greenfield Projects:**
```markdown
# 🔍 Workspace Detection Complete

Workspace analysis findings:
• **Project Type**: Greenfield project
• **Layout**: [Single-folder | Multi-folder]
• **Docs Root**: `[absolute path]`
• **Workspace Root(s)**: `[list of selected workspace roots]`
• **Next Step**: Proceeding to **Requirements Analysis**...
```

## Step 9: Automatically Proceed

- **No user approval required for the detection itself** — this is informational. (If a multi-candidate workspace required a target-selection question in Step 5, that question must be answered before proceeding.)
- Automatically proceed to next phase:
  - **Brownfield**: Reverse Engineering (if no existing artifacts) or Requirements Analysis (if artifacts exist)
  - **Greenfield**: Requirements Analysis
