---
name: feature-to-plan
description: Create a local implementation plan from a prompt or feature description. Writes a markdown plan file for developer review and sign-off before any code changes are made.
---

# Feature → Plan skill

Produces a scoped implementation plan written to `doc/implementation/` and **stops**. No branches, no code changes, no commits. The developer reviews and edits the plan, then hands it to the `implement-plan` skill.

No external ticketing system is used in this repo — all work is prompt-driven.

---

## Inputs to collect at runtime

- REQUIREMENTS_TEXT (from the user's prompt)
- REPO_OWNER / REPO_NAME (default: rdytech/ewp-stack-sentinel)

---

## Step 0 — Decide if a plan is needed

Classify the request:

### Simple request (no plan needed)
Choose **simple** when:
- The user asks for explanation, review, or a small one-off answer
- No code changes are requested OR changes are purely conceptual

Action: Respond with the answer/instructions. Do not create a plan file.

### Actioned (create a plan)
Choose **actioned** when:
- The user asks to implement a feature, bugfix, or chore
- Changes imply tests, a PR, and/or review

Record your decision briefly:
- "Classification: simple" OR "Classification: actioned"
- One-sentence justification.

---

## Step 1 — Acquire scope & constraints

1. Parse REQUIREMENTS_TEXT into:
   - intended behavior
   - acceptance checks
   - out-of-scope assumptions
2. Read `AGENTS.md` and `README.md` for repo conventions and architecture context.
3. Explore the codebase to identify:
   - Files / components likely to change
   - Existing patterns to follow
   - Tests to add or modify
   - Config or CSV schema changes required

---

## Step 2 — Derive plan file name

1. Derive a short title from REQUIREMENTS_TEXT.
2. Generate a slug: `.claude/skills/shared/scripts/slugify.sh "<short title>"`
3. Plan file path: `doc/implementation/<slug>.md`

---

## Step 3 — Write the implementation plan

Create the plan file at the path determined in Step 2. Include all sections below.

```markdown
# Implementation Plan: <title>

## Requirements
<bullet list from prompt>

## Acceptance Criteria
<bullet list>

## Out of scope
<bullet list>

## Approach
<narrative description of the implementation strategy, patterns to follow>

## Files to change
| File | Change |
|------|--------|
| config/repos.yml | ... |
| lib/sentinel/detectors/... | ... |
| ... | ... |

## Tests to add / modify
| File | What to test |
|------|-------------|
| spec/... | ... |

## Config / schema changes
<list any changes to config/repos.yml structure, per-project config format, or CSV columns — or "None">

## Risks & assumptions
<list>

## Questions / open items
<list any uncertainties for developer to resolve before implementation begins>
```

---

## Step 4 — Present plan and stop

1. Print the relative path of the created plan file.
2. Briefly summarise key decisions and any open questions.
3. **Stop. Do not proceed further.**

Instruct the developer to:
- Review and edit the plan file at `doc/implementation/<filename>.md`
- Resolve any open questions
- Then invoke the `implement-plan` skill with that file path to begin coding

> **This skill makes no code changes, creates no branches, and produces no commits.**

---

## ⏭️ Next step

Once you have reviewed and are happy with the plan:

> Run the **`implement-plan`** skill with the plan file path to begin coding.
