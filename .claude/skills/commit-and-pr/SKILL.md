---
name: commit-and-pr
description: Take all existing uncommitted (or staged) changes, break into reasonable commits, split into separate PRs if above the 500-line LoC limit, push branches, and open PRs.
---

# Commit and PR skill

Commits all current working-tree changes, respects the 500-line PR size limit by splitting into multiple PRs where needed, pushes branches, and creates GitHub PRs.

Tooling (via MCP):
- GitHub MCP (push/create PR)

---

## Inputs to collect at runtime

- BASE_BRANCH (default: master)
- REPO_OWNER / REPO_NAME (default: rdytech/ewp-stack-sentinel)

---

## Step 1 — Assess current state

1. Run `git status` to confirm there are changes to commit.
2. If working tree is clean, stop and inform the developer there is nothing to commit.
3. Run:
   ```bash
   git diff --stat <BASE_BRANCH>...HEAD
   ```
   Also account for any unstaged changes:
   ```bash
   git diff --stat
   git diff --cached --stat
   ```
4. Sum total additions + deletions across **all** changes (staged + unstaged + committed since base).
5. Note the current branch name.

---

## Step 2 — Decide: single PR or split

### Single PR (≤ 500 lines total)
- All changes go into one commit on the current branch → one PR.
- Proceed to Step 3a.

### Split required (> 500 lines total)
- Identify natural seams. Prefer splitting by layer in this order:
  1. Configuration (base config, per-project configs)
  2. Core library / detectors (`lib/sentinel/`)
  3. CLI / entrypoint (`bin/`)
  4. Tests (specs for any of the above)
- Each split must be **independently mergeable** — no broken intermediate state.
- Each split must be ≤ 500 lines.
- Produce and display the split plan before proceeding:
  ```
  PR 1: <description>  (~N lines)
  PR 2: <description>  (~N lines)
  PR 3: <description>  (~N lines)
  ```
- Proceed to Step 3b.

---

## Step 3a — Single PR: commit and push

1. Stage all changes: `git add -A`
   - **Exclude** any files under `docs/superpowers/` — unstage them if picked up: `git reset HEAD docs/superpowers/`
2. Commit: `git commit -m "<short summary>"`
3. Push: `git push -u origin <current-branch>`
4. Create PR (Step 4).

---

## Step 3b — Split PRs: stash, branch, cherry-pick

For each split (PR 1, PR 2, …):

1. From the base branch, create a new branch: `git checkout -b <current-branch>-part-N`
2. Apply only the files belonging to this split:
   - Use `git checkout <source-branch> -- <files>` to selectively bring in changes.
   - Stage and commit:
     ```
     git add <files for this split>
     git reset HEAD docs/superpowers/  # never include implementation plans
     git commit -m "<summary> (part N/M)"
     ```
3. Verify this split is ≤ 500 lines: `git diff --stat <BASE_BRANCH>...HEAD`
4. Push: `git push -u origin <branch>`
5. Repeat for each subsequent split.

> After all splits are pushed, the original working branch can be deleted locally if it is now fully represented by the split branches. Ask the developer before deleting.

---

## Step 4 — Create GitHub PRs (GitHub MCP)

For each branch (single or split):

1. Create a **draft** PR targeting BASE_BRANCH.
2. PR title: `<summary>` (no ticket prefix).
3. PR body structure:
   - **What does this PR do?**: Concise dot-point list covering:
     - What changed in this PR.
     - How to test (commands and expected outcome).
     - Risks / rollout notes (or "None").
     - Related PRs (list sibling PRs if this is a split; or "N/A").
   - **Screenshots**: "No UI changes" (this is a CLI/data tool).

---

## Output discipline
- Never include secrets in commit messages or PRs.
- Never commit or push anything under `docs/superpowers/` — these are local planning artefacts only.
- Keep PR summaries grounded in actual changes (`git diff --stat`).
- Do not broaden scope without explicitly calling it out.
- Verify each split PR is independently reviewable and mergeable before posting.
