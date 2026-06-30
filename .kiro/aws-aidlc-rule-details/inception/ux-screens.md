# UX Screens - Detailed Steps

## Purpose
**Capture the screen/UX contract right after requirements, and reconcile it against them**

UX Screens focuses on:
- Establishing the visual and interaction contract for user-facing work
- Sourcing screens flexibly: **provided** (Figma via an MCP capability, or screenshots/images/links), **generated** (HTML mockups in a chosen component library), or already **given upfront** with the PRD
- Producing a reviewable screen inventory mapped to a chosen component library
- Documenting screen flows tied to requirements
- Reconciling the screens against `requirements.md` and surfacing conflicts/gaps/ambiguities for the user to act on
- Feeding concrete screens into Application Design (component mapping) and Units Generation

**Note**: This stage captures *what the UI is*, not *how it is implemented*. Generated HTML mockups are **design artifacts** that live in `aidlc-docs/` — they are NOT application code (which always goes into a `<WORKSPACE-ROOT>` during Construction).

## Requirements Ownership (CRITICAL)

**UX Screens NEVER edits `requirements.md`.** This stage produces a **read-only reconciliation report**. If the screens reveal that requirements should change, the user chooses **Revise Requirements**, which hands the findings back to **Requirements Analysis** — the sole owner of `requirements.md` — to regenerate and re-approve through its own gate. There is no bespoke re-gating logic here.

## Prerequisites
- Workspace Detection must be complete
- Requirements Analysis must be complete (`requirements.md` exists). Screens are always sourced *after* requirements — you cannot reliably generate screens from a vague PRD, and provided screens are reconciled against the drafted requirements.
- Reverse Engineering recommended when brownfield (informs the existing UI library/patterns)

## Intelligent Assessment Guidelines

### Execute IF (user-facing UI work)
- New user-facing screens, pages, views, dialogs, or panels
- Modifications to existing screens, layouts, or user workflows
- Multi-persona interfaces with different views
- New product capabilities that introduce or reshape a UI
- Work where a screen/flow contract improves clarity and testability

### Skip IF (no user-facing surface)
- Backend-only changes, services, jobs, or data work with no UI
- Pure refactoring with no UI impact
- Infrastructure-only changes
- API-only changes with no screen impact
- Documentation-only updates

**Note**: This is the same "is this user-facing?" judgment that User Stories uses. If both stages run, do not re-ask the user the same framing question — reuse the assessment.

---

# PART 1: MODE SELECTION + PLANNING

## Step 1: Validate UX Screens Need (MANDATORY)
1. **Analyze Request Context**: Review the request and `requirements.md`. Identify whether the work introduces or changes any user-facing surface.
2. **Apply Assessment Criteria**: Check against the Execute / Skip indicators above.
3. **Document Assessment Decision**: Create `aidlc-docs/inception/plans/ux-screens-assessment.md` with the reasoning and expected downstream benefit.
4. **Proceed Only If Justified**: If skipping, record the rationale and move to Workflow Planning.

## Step 2: Re-Entry Check (Idempotency)

**Before sourcing**, check `aidlc-state.md` for existing screen provenance:
- **If screens were already captured this session** (e.g. the stage is being re-entered after a requirements revision): **skip Step 3–4 sourcing entirely** and go straight to **PART 3 (Reconciliation)** to re-reconcile the existing screens against the updated `requirements.md`. **Never re-ask the user for screens they already provided.**
- Otherwise, continue to Step 3.

## Step 3: Create the Plan and Ask the Sourcing Question

- Assume the role of a product designer working with the product owner.
- Create `aidlc-docs/inception/plans/ux-screens-plan.md` with a step-by-step checklist and embed questions using `[Answer]:` tags (see `common/question-format-guide.md`).

**The sourcing question is ADAPTIVE.** First check `aidlc-state.md` for screens recorded as `provided-upfront` (captured during Requirements Analysis intake).

**IF screens were provided upfront**, surface them and ask:

```markdown
## Question: Screen Sourcing
You provided screens earlier ([list the upfront screens/links]). How should we proceed?

A) Use these as-is

B) Add / upload more screens (keep these + provide more)

C) Replace them with new screens

D) Generate screens for me

E) Skip UX Screens

X) Other (please describe after [Answer]: tag below)

[Answer]: 
```

**IF no screens are present yet**, ask:

```markdown
## Question: Screen Sourcing
How should the screens for this feature be sourced?

A) Provide via Figma — I have designs in Figma

B) Provide via screenshots / images / links — I'll supply files, paths, or URLs

C) Generate screens for me — AI-DLC proposes screens as HTML mockups

D) Skip UX Screens — no screen contract needed

X) Other (please describe after [Answer]: tag below)

[Answer]: 
```

### Step 3.1: Branch on the Answer

- **Provide via Figma**: **Just ask** the user "Is a Figma MCP connected in this session?" (do not rely on silent capability detection). If yes, ask for the file / frame / node references and retrieve the frames. If no, fall back to screenshots/images/links.
- **Provide via screenshots / images / links**: ask for asset paths (in the workspace) or URLs; catalogue each.
- **Generate**: proceed to Step 4 (generation questions).
- **Hybrid (Add more / generate gaps)**: ingest the existing set, then treat the missing screens as a generation request (Step 4), scoped to the gaps only.
- **Use as-is**: no new sourcing; proceed to PART 2 to build the inventory from the provided screens.
- **Skip**: record the skip decision and rationale in `ux-screens-assessment.md` and `aidlc-state.md`, then proceed to Workflow Planning.

## Step 4: Generation Follow-Up Questions (only when generating, incl. hybrid gap-fill)

```markdown
## Question: Component Library
Which component library / design system should the generated screens use?

A) Carbon (IBM Carbon Design System) — recommended default

B) Material UI

C) Ant Design

D) Generic / library-agnostic (button, table, modal — no specific library)

X) Other (please describe after [Answer]: tag below)

[Answer]: 
```

**Brownfield default**: if reverse-engineering artifacts exist, default to the **existing app's UI library and patterns** (so mockups look like they belong) rather than Carbon, and say so when presenting the question.

Also ask (separate `[Answer]:` questions):
- **Screens & flows to cover**: propose a list derived from `requirements.md` (for hybrid, only the gaps); ask to confirm/extend.
- **Fidelity**: **lo-fi (default)** vs hi-fi. Lo-fi keeps inception fast.
- **States**: empty / loading / error / populated (which apply per screen).
- **Responsive targets**: desktop / tablet / mobile.
- **Brand / theming constraints**.

**Generation precondition**: only generate after `requirements.md` is approved. Treat generated screens as a **draft that drives clarifying questions**, not a final contract.

## Step 5: ANALYZE ANSWERS (MANDATORY)
Review answers for vague/ambiguous responses ("mix of", "not sure", "depends"), undefined terms, contradictions, and missing detail needed to source or generate screens.

## Step 6: MANDATORY Follow-up Questions
If Step 5 reveals ANY ambiguity, add follow-up `[Answer]:` questions to the plan. Do NOT proceed to generation until resolved.

## Step 7: Log Approval Prompt
Log the approval prompt with an ISO 8601 timestamp in `aidlc-docs/audit.md`.

## Step 8: Wait for Explicit Approval of Plan
Do not proceed to PART 2 until the user approves the sourcing decision and (if generating) the library, screen list, fidelity, and states. If changes are requested, update the plan and repeat.

## Step 9: Record Approval Response
Log the user's approval response with an ISO 8601 timestamp in `aidlc-docs/audit.md`.

---

# PART 2: INGEST / GENERATE + PERSIST ARTIFACTS

## Step 10: Load the Approved Plan
- [ ] Read `aidlc-docs/inception/plans/ux-screens-plan.md`
- [ ] Load `requirements.md` for context
- [ ] Identify the sourcing mode and (if generating) the library, screens, fidelity, states

## Step 11: Produce Screen Artifacts

**MANDATORY**: Validate ASCII content per `common/ascii-diagram-standards.md` and follow `common/content-validation.md` before writing any file.

Create artifacts under `aidlc-docs/inception/ux-screens/`:

- [ ] `screens.md` — Screen inventory. For each screen: name, purpose, key elements, applicable states, and an explicit **component mapping** to the chosen library.
- [ ] `screen-flows.md` — Navigation and flows between screens, mapped to requirements.
- [ ] `design-system.md` — Chosen component library, components used, and tokens/theming notes.
- [ ] `mockups/` — one file per screen:
  - **Generate / hybrid**: a self-contained **HTML mockup** per screen using the chosen library's markup (Carbon by default; existing app's library when brownfield). **Lo-fi by default.** Each mockup MUST start with a visible banner comment marking it a throwaway design artifact, e.g. `<!-- THROWAWAY MOCKUP — design artifact, NOT implementation. Do not ship. -->`.
  - **Provide (Figma)**: reference the Figma file/frame/node per screen, plus a short description.
  - **Provide (images)**: reference the provided asset path/URL per screen, plus a short description.

**Reminder**: These mockups are **design artifacts** under `aidlc-docs/`. They do NOT violate the "code never in aidlc-docs" rule, which governs application/build code in a `<WORKSPACE-ROOT>`.

## Step 12: Record Provenance + Progress
- [ ] Record screen provenance in `aidlc-state.md`: `upfront` / `provided-now` / `generated` / `hybrid`, with locations.
- [ ] Mark completed steps `[x]` in the plan; update `aidlc-state.md` status.

---

# PART 3: SCREEN ⇄ REQUIREMENTS RECONCILIATION (READ-ONLY)

## Step 13: Compare Screens Against Requirements
- Load `aidlc-docs/inception/requirements/requirements.md`.
- Compare the screens (provided or generated) against it. Classify each finding:
  - **Conflict** — a screen contradicts a stated requirement.
  - **Gap** — a screen shows fields/states/behavior/flows the requirements omit.
  - **Ambiguity** — a screen raises a question the requirements do not answer.

## Step 14: Write the Reconciliation Report (READ-ONLY)
- Write `aidlc-docs/inception/ux-screens/requirements-reconciliation.md` listing the findings. Each finding cites the **screen** and the **relevant requirement** (or notes its absence).
- **DO NOT modify `requirements.md`. DO NOT ask `[Answer]:` questions here. DO NOT re-gate requirements.** This step only reports.
- If there are no findings, record "screens consistent with requirements" in `aidlc-docs/audit.md`.

---

# COMPLETION

## Step 15: Log Approval Prompt
Log the approval prompt with an ISO 8601 timestamp in `aidlc-docs/audit.md`.

## Step 16: Present Completion Message

```markdown
# 🎨 UX Screens Complete
```

Then an optional factual summary (screens captured + sourcing mode, component library, flows, and a short summary of the reconciliation findings), followed by this exact format:

```markdown
> **📋 <u>**REVIEW REQUIRED:**</u>**  
> Please examine the UX screens at: `aidlc-docs/inception/ux-screens/` (including `requirements-reconciliation.md`)



> **🚀 <u>**WHAT'S NEXT?**</u>**
>
> **You may:**
>
> 🔧 **Request Changes** - Ask for modifications to the screens, flows, or component mapping  
> [IF the reconciliation report has findings, add this option:]
> 📝 **Revise Requirements** - Apply the screen findings to the requirements (this re-runs Requirements Analysis, which owns and regenerates `requirements.md`)  
> ✅ **Approve & Continue** - Approve the screens and proceed to **[User Stories/Workflow Planning]**

---
```

**Note**: Include "Revise Requirements" only when `requirements-reconciliation.md` has findings. Replace `[User Stories/Workflow Planning]` with the actual next stage.

## Step 17: Handle the User's Choice
- **Request Changes**: update the screen artifacts and re-present.
- **Revise Requirements**: route back to **Requirements Analysis as a revision**, passing the reconciliation findings. Requirements Analysis (its existing rules) folds them in, regenerates `requirements.md`, and re-approves through its own gate; the re-run is logged in `aidlc-state.md` / `audit.md` tagged `revision: screen reconciliation`. **Convergence**: Requirements Analysis's "WHAT'S NEXT" routes back to UX Screens, which re-enters idempotently (Step 2 → straight to PART 3), re-reconciles against the updated requirements, and — once the report is clean — the user chooses Approve & Continue. UX Screens never edits `requirements.md` itself.
- **Approve & Continue**: proceed to the next stage.

## Step 18: Record Approval Response + Update Progress
- Log the user's response with an ISO 8601 timestamp in `aidlc-docs/audit.md`.
- Mark UX Screens stage complete in `aidlc-docs/aidlc-state.md` and update "Current Status".

---

# CRITICAL RULES

## Planning Phase Rules
- **REQUIREMENTS FIRST**: never run before `requirements.md` exists; never generate screens from a vague PRD.
- **ADAPTIVE SOURCING**: recognize upfront screens and offer use/add/replace; do not re-ask for screens already provided.
- **ASK, DON'T DETECT** for Figma MCP: ask the user whether a Figma MCP is connected; fall back to screenshots/links.
- **EXPLICIT APPROVAL REQUIRED** before generation.

## Generation Phase Rules
- **DESIGN ARTIFACTS ONLY**: HTML mockups are design artifacts in `aidlc-docs/`, lo-fi by default, banner-marked throwaway.
- **BROWNFIELD**: prefer the existing app's UI library/patterns over Carbon when reverse-engineering artifacts exist.
- **RECORD PROVENANCE** in `aidlc-state.md` for resume + idempotent re-entry.

## Reconciliation Phase Rules
- **READ-ONLY**: UX Screens never edits `requirements.md`, never asks `[Answer]:` questions, never re-gates requirements.
- **HAND-BACK**: requirements changes happen only inside Requirements Analysis, via the "Revise Requirements" choice.

## Completion Criteria
- Sourcing decided and (if generating) library/screens/fidelity approved
- Screen artifacts generated (screens.md, screen-flows.md, design-system.md, mockups/)
- `requirements-reconciliation.md` written (read-only)
- Provenance recorded in `aidlc-state.md`
- User approved; screens ready for Workflow Planning and Application Design
