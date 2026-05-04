---
name: implement-plan
description: Given an implementation plan file in doc/implementation/, make all required code changes and specs, confirm specs pass for the changed files, then stop for developer review before committing.
---

# Implement Plan skill

Reads a plan file from `doc/implementation/`, implements all required changes, verifies tests pass, and **stops** before committing or pushing. The developer reviews, tweaks, and then hands off to the `commit-and-pr` skill.

---

## Inputs to collect at runtime

- PLAN_FILE — relative path to the implementation plan (e.g. `doc/implementation/add-sidekiq-detector.md`)
- BASE_BRANCH (default: master)

---

## Step 1 — Read and validate the plan

1. Read PLAN_FILE.
2. Confirm the file exists and contains at minimum: Requirements, Approach, Files to change, Tests to add/modify.
3. If the file is missing or incomplete, stop and ask the developer to provide a valid plan file (created by the `feature-to-plan` skill).
4. Extract:
   - List of files to change with their intended modifications
   - List of test files to add/modify
   - Any config or CSV schema changes required

---

## Step 2 — Sync base branch

1. Run:
   - `git checkout <BASE_BRANCH>`
   - `git pull --ff-only`

---

## Step 3 — Create or switch to working branch

1. Derive slug from the plan file name (strip `doc/implementation/` prefix and `.md` suffix).
2. Branch name: `<slug>` (e.g. `add-sidekiq-detector`).
3. Create or switch to the branch:
   - `git checkout -b <branch>` (or `git checkout <branch>` if it already exists)

> If already on the correct branch (e.g. the developer has been iterating), skip branch creation.

---

## Step 4 — Implement changes

Follow the plan strictly. For each entry in "Files to change":

1. Make the **minimal** change described in the plan.
2. Follow all repo conventions in `AGENTS.md` and `README.md`.
3. Do not make drive-by refactors outside the plan.
4. After all source changes, implement the tests listed in "Tests to add/modify".
5. If the plan includes config or CSV schema changes:
   - Update `config/repos.yml` structure and/or per-project config format as described
   - Update `README.md` and `AGENTS.md` to reflect any column or schema changes

---

## Step 5 — Run changed/added tests only

Run:
```
.claude/skills/shared/scripts/run_changed_tests.sh
```

Fix any failures until green. Do not proceed until all changed-file tests pass.

---

## Step 6 — Run bin/ci if present

Run:
```
.claude/skills/shared/scripts/run_ci.sh
```

Fix any failures until green.

---

## Step 7 — PR size check (informational)

Run:
```bash
git diff --stat <BASE_BRANCH>...HEAD
```

Sum total additions + deletions.

- **≤ 500 lines** → note this in the summary. `commit-and-pr` will create a single PR.
- **> 500 lines** → flag this prominently. `commit-and-pr` will need to split into multiple PRs; suggest logical seams to the developer.

> Do not split or commit anything here — that is the responsibility of `commit-and-pr`.

---

## Step 8 — Stop and present summary

Print a summary including:
- Files changed and a brief description of each change
- Test files added/modified
- PR size estimate (additions + deletions)
- Whether size is within the 500-line limit
- Any open items or issues encountered during implementation

Instruct the developer to:
- Review the changes (e.g. `git diff`, open files in editor)
- Make any tweaks directly
- When satisfied, invoke the `commit-and-pr` skill to commit, split if needed, push, and open PRs

> **This skill does not commit, push, or open PRs.**

---

## ⏭️ Next step

Once you have reviewed the changes and are satisfied they work correctly:

> Run the **`commit-and-pr`** skill to commit, push, and open PRs.
