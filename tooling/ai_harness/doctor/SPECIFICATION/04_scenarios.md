# Doctor Script — Scenarios

## Table of Contents

1. [Happy Path Scenarios](#1-happy-path-scenarios)
2. [Parity Check Scenarios](#2-parity-check-scenarios)
3. [.ai/ Reference Scenarios](#3-ai-reference-scenarios)
4. [.gitignore Scenarios](#4-gitignore-scenarios)
5. [Forbidden Files Scenarios](#5-forbidden-files-scenarios)
6. [Combined Scenarios](#6-combined-scenarios)
7. [Argument Parsing Scenarios](#7-argument-parsing-scenarios)

Each scenario describes a state of the repository and the expected doctor
behavior. Scenarios are organized by check and by happy-path vs error cases.

Scenario headings use `category: description` format. Cross-references
within this file use the heading text (e.g., "same Given as
`parity: missing CLAUDE.md at root`").

---

## 1. Happy Path Scenarios

### happy: clean repo passes all checks

**Given:** A repo with:

- `AGENTS.md` and `CLAUDE.md` at root with identical content
- `AGENTS.md` references `.ai/git.md` and `.ai/testing.md`
- `.ai/git.md` and `.ai/testing.md` exist
- `.gitignore` contains `CLAUDE.local.md` and `.ai/*`
- No forbidden files staged or committed

**When:** `scripts/ai_harness/doctor`

**Then:** All checks show `OK`, exit code 0

### happy: subdirectory pairs also pass

**Given:** Same as `happy: clean repo passes all checks`, plus:

- `sub/AGENTS.md` and `sub/CLAUDE.md` with identical content

**When:** `scripts/ai_harness/doctor`

**Then:** All checks show `OK`, exit code 0

### happy: --help prints help and exits

**When:** `scripts/ai_harness/doctor --help`

**Then:** Help text printed to stdout (includes "Usage:", "--fix", "--help"),
exit code 0, no checks run. `ParseArgv` sets `print_help: true` on the
ok path. `HandleAction` sets `stdout_text` from `HelpText` and skips the
`PerformDoctorChecks` sub-chain.

### happy: gitignored tool files are fine

**Given:** Same as `happy: clean repo passes all checks`, plus:

- `.claude/rules/my-rule.md` exists on disk but is gitignored
- `.opencode/config.json` exists on disk but is gitignored

**When:** `scripts/ai_harness/doctor`

**Then:** All checks show `OK`, exit code 0 (gitignored files are not flagged)

### happy: --fix on an already-valid repo is a no-op

**Given:** Same as `happy: clean repo passes all checks` (everything valid)

**When:** `scripts/ai_harness/doctor --fix`

**Then:** All checks show `OK`, exit code 0, no files changed

---

## 2. Parity Check Scenarios

### parity: missing CLAUDE.md at root

**Given:** `AGENTS.md` exists at root, `CLAUDE.md` does not

**When:** `scripts/ai_harness/doctor`

**Then:** Parity check shows `FAIL` with detail
`CLAUDE.md not found (AGENTS.md exists)` — no directory prefix for root-level
issues. Exit code 1.

### parity: missing AGENTS.md at root

**Given:** `CLAUDE.md` exists at root, `AGENTS.md` does not

**When:** `scripts/ai_harness/doctor`

**Then:** Parity check shows `FAIL` with detail
`AGENTS.md not found (CLAUDE.md exists)` — no directory prefix for root-level
issues. Exit code 1.

### parity: content differs at root

**Given:** Both exist at root but have different content

**When:** `scripts/ai_harness/doctor`

**Then:** Parity check shows `FAIL` with "differs from AGENTS.md" — no
directory prefix for root-level issues. Exit code 1.

### parity: subdirectory pair content differs

**Given:** Root pair is valid. `sub/AGENTS.md` and `sub/CLAUDE.md` exist
with different content

**When:** `scripts/ai_harness/doctor`

**Then:** Parity check shows `FAIL` with "sub/" in details, exit code 1

### parity: subdirectory file missing

**Given:** Root pair is valid. `sub/AGENTS.md` exists but `sub/CLAUDE.md`
does not

**When:** `scripts/ai_harness/doctor`

**Then:** Parity check shows `FAIL` with "sub/" in details, exit code 1

### parity: deeply nested subdirectory shows full relative path

**Given:** Root pair is valid. `a/b/c/AGENTS.md` exists but
`a/b/c/CLAUDE.md` does not

**When:** `scripts/ai_harness/doctor`

**Then:** Parity check shows `FAIL` with "a/b/c/" in details (full relative
path from repo root, not just the leaf directory name). Exit code 1.

### parity: --fix syncs CLAUDE.md from AGENTS.md

**Given:** Both exist at root, content differs

**When:** `scripts/ai_harness/doctor --fix`

**Then:** CLAUDE.md content now matches AGENTS.md, parity check shows `FIXED`

### parity: --fix creates missing CLAUDE.md

**Given:** `AGENTS.md` exists at root, `CLAUDE.md` does not

**When:** `scripts/ai_harness/doctor --fix`

**Then:** `CLAUDE.md` created with AGENTS.md content, parity check shows `FIXED`

### parity: --fix creates missing AGENTS.md from CLAUDE.md

**Given:** `CLAUDE.md` exists at root, `AGENTS.md` does not

**When:** `scripts/ai_harness/doctor --fix`

**Then:** `AGENTS.md` created with CLAUDE.md content, parity check shows `FIXED`

### parity: --fix repairs subdirectory pair

**Given:** Root pair is valid. `sub/AGENTS.md` exists but `sub/CLAUDE.md`
does not

**When:** `scripts/ai_harness/doctor --fix`

**Then:** `sub/CLAUDE.md` created with `sub/AGENTS.md` content, parity
check shows `FIXED`

### parity: CLAUDE.md is a symlink to AGENTS.md

**Given:** `AGENTS.md` exists at root as a regular file. `CLAUDE.md` is a
symlink pointing to `AGENTS.md`.

**When:** `scripts/ai_harness/doctor`

**Then:** Parity check shows `FAIL` with detail including "symlink" and
"CLAUDE.md". Exit code 1.

### parity: AGENTS.md is a symlink

**Given:** `CLAUDE.md` exists at root as a regular file. `AGENTS.md` is a
symlink pointing to `CLAUDE.md`.

**When:** `scripts/ai_harness/doctor`

**Then:** Parity check shows `FAIL` with detail including "symlink" and
"AGENTS.md". Exit code 1.

### parity: subdirectory symlink detected

**Given:** Root pair is valid. `sub/AGENTS.md` is a regular file.
`sub/CLAUDE.md` is a symlink.

**When:** `scripts/ai_harness/doctor`

**Then:** Parity check shows `FAIL` with "sub/" prefix and "symlink" in
details. Exit code 1.

### parity: --fix replaces symlink with regular file

**Given:** `AGENTS.md` exists at root as a regular file. `CLAUDE.md` is a
symlink pointing to `AGENTS.md`.

**When:** `scripts/ai_harness/doctor --fix`

**Then:** Symlink is replaced with a regular file containing the same
content. Parity check shows `FIXED`. `CLAUDE.md` is no longer a symlink.

---

## 3. .ai/ Reference Scenarios

### references: missing reference target

**Given:** `AGENTS.md` contains `.ai/missing.md`, file does not exist

**When:** `scripts/ai_harness/doctor`

**Then:** Reference check shows `FAIL` with ".ai/missing.md" and "does not exist",
exit code 1

### references: all references resolve

**Given:** `AGENTS.md` references `.ai/git.md`, file exists

**When:** `scripts/ai_harness/doctor`

**Then:** Reference check shows `OK`

### references: no references is valid

**Given:** `AGENTS.md` contains no `.ai/*` references

**When:** `scripts/ai_harness/doctor`

**Then:** Reference check shows `OK`

### references: subdirectory AGENTS.md resolves .ai/ relative to its own directory

**Given:** `sub/AGENTS.md` references `.ai/git.md`. `sub/.ai/git.md` exists
but `repo_root/.ai/git.md` does not.

**When:** `scripts/ai_harness/doctor`

**Then:** Reference check shows `OK` — `.ai/git.md` is resolved relative to
`sub/`, finding `sub/.ai/git.md`. This allows directories containing
`AGENTS.md` to be moved without breaking their `.ai/` references.

### references: subdirectory AGENTS.md missing file-relative .ai/ reference

**Given:** `sub/AGENTS.md` references `.ai/git.md`. Neither `sub/.ai/git.md`
nor `repo_root/.ai/git.md` exists.

**When:** `scripts/ai_harness/doctor`

**Then:** Reference check shows `FAIL` with `sub/.ai/git.md` — the reference is
resolved relative to `sub/` and displayed with the full relative path from the
repo root.

### references: --fix does not fix missing references

**Given:** Same as `references: missing reference target`

**When:** `scripts/ai_harness/doctor --fix`

**Then:** Reference check still shows `FAIL` (not auto-fixable), exit code 1

---

## 4. .gitignore Scenarios

### gitignore: missing CLAUDE.local.md entry

**Given:** `.gitignore` has `.ai/*` but not `CLAUDE.local.md`

**When:** `scripts/ai_harness/doctor`

**Then:** Gitignore check shows `FAIL` with "CLAUDE.local.md", exit code 1

### gitignore: missing .ai/* entry

**Given:** `.gitignore` has `CLAUDE.local.md` but not `.ai/*`

**When:** `scripts/ai_harness/doctor`

**Then:** Gitignore check shows `FAIL` with ".ai/*", exit code 1

### gitignore: .gitignore not found

**Given:** No `.gitignore` file exists

**When:** `scripts/ai_harness/doctor`

**Then:** Gitignore check shows `FAIL`, exit code 1

### gitignore: rooted entries do not satisfy the check

**Given:** `.gitignore` contains `/CLAUDE.local.md` (rooted) instead of
`CLAUDE.local.md` (non-rooted)

**When:** `scripts/ai_harness/doctor`

**Then:** Gitignore check shows `FAIL` with "CLAUDE.local.md", exit code 1.
Rooted patterns only match at the repository root, but these entries must
be non-rooted to match at all directory levels.

### gitignore: --fix appends missing entries

**Given:** `.gitignore` exists but is empty

**When:** `scripts/ai_harness/doctor --fix`

**Then:** Both entries appended, gitignore check shows `FIXED`

---

## 5. Forbidden Files Scenarios

### forbidden: .claude/rules/ file committed

**Given:** `.claude/rules/my-rule.md` is tracked by git (staged or committed)

**When:** `scripts/ai_harness/doctor`

**Then:** Forbidden files check shows `FAIL` with the file path, exit code 1

### forbidden: file in allowlist YAML is allowed

**Given:** A file matching an entry in `config.yml` is
tracked by git

**When:** `scripts/ai_harness/doctor`

**Then:** Forbidden files check shows `OK` — the file is intentionally
committed project content.

### forbidden: allowed and personal files mixed

**Given:** Both an allowlisted file and a non-allowlisted forbidden file
are tracked by git

**When:** `scripts/ai_harness/doctor`

**Then:** Forbidden files check shows `FAIL` listing only the
non-allowlisted file.

### forbidden: file outside allowlist YAML is committed

**Given:** A `.claude/skills/` file not in `config.yml`
is tracked by git

**When:** `scripts/ai_harness/doctor`

**Then:** Forbidden files check shows `FAIL`, exit code 1

### forbidden: .claude/settings.json committed

**Given:** `.claude/settings.json` is tracked by git

**When:** `scripts/ai_harness/doctor`

**Then:** Forbidden files check shows `FAIL`, exit code 1

### forbidden: .opencode/ file committed

**Given:** `.opencode/config.json` is tracked by git

**When:** `scripts/ai_harness/doctor`

**Then:** Forbidden files check shows `FAIL`, exit code 1

### forbidden: .gitlab/duo/chat-rules.md committed

**Given:** `.gitlab/duo/chat-rules.md` is tracked by git

**When:** `scripts/ai_harness/doctor`

**Then:** Forbidden files check shows `FAIL`, exit code 1

### forbidden: .gitlab/duo/mcp.json committed

**Given:** `.gitlab/duo/mcp.json` is tracked by git

**When:** `scripts/ai_harness/doctor`

**Then:** Forbidden files check shows `FAIL`, exit code 1

### forbidden: AGENTS.local.md force-committed at root

**Given:** `AGENTS.local.md` is tracked by git (force-added with
`git add --force`) at the repo root

**When:** `scripts/ai_harness/doctor`

**Then:** Forbidden files check shows `FAIL` with the file path, exit code 1.
This prevents personal local overrides from being accidentally shared.

### forbidden: CLAUDE.local.md force-committed at root

**Given:** `CLAUDE.local.md` is tracked by git at the repo root

**When:** `scripts/ai_harness/doctor`

**Then:** Forbidden files check shows `FAIL`, exit code 1.

### forbidden: AGENTS.local.md force-committed in subdirectory

**Given:** `sub/AGENTS.local.md` is tracked by git

**When:** `scripts/ai_harness/doctor`

**Then:** Forbidden files check shows `FAIL` with the file path, exit code 1.
The `**/AGENTS.local.md` pattern catches local files at any depth.

### forbidden: gitignored files are not flagged

**Given:** `.claude/rules/my-rule.md` exists on disk but is NOT tracked
by git (gitignored or in `.git/info/exclude`)

**When:** `scripts/ai_harness/doctor`

**Then:** Forbidden files check shows `OK`

### forbidden: all remaining patterns are detected

**Given:** The following files are each tracked by git:

- `.claude/agents/my-agent.md`
- `.claude/commands/my-cmd.md`
- `.claude/settings.local.json`
- `.claude/settings.local.jsonc`

**When:** `scripts/ai_harness/doctor`

**Then:** Forbidden files check shows `FAIL` listing all four file paths,
exit code 1. (This supplements the per-pattern scenarios above, which cover
the remaining forbidden patterns individually.)

### forbidden: --fix does NOT fix forbidden files

**Given:** Same as `forbidden: .claude/rules/ file committed`

**When:** `scripts/ai_harness/doctor --fix`

**Then:** Forbidden files check still shows `FAIL` (hard fail, not auto-fixable),
exit code 1

---

## 6. Combined Scenarios

### combined: multiple failures reported

**Given:** CLAUDE.md missing AND .gitignore missing `CLAUDE.local.md` entry

**When:** `scripts/ai_harness/doctor`

**Then:** Both parity check and gitignore check show `FAIL`, exit code 1.
All four checks run — the chain does not short-circuit on individual failures.

### combined: --fix fixes what it can, reports what it can't

**Given:** CLAUDE.md content differs (fixable) AND `.claude/rules/foo.md`
committed (not fixable)

**When:** `scripts/ai_harness/doctor --fix`

**Then:** Parity check shows `FIXED`, forbidden files check shows `FAIL`,
exit code 1. All checks run regardless of individual outcomes.

### combined: unmatched result raises error

**Given:** The ROP chain produces a `Result` variant that does not match
any arm in `Main.main`'s pattern match (e.g., a new `Result.err` message
type is added to `ParseArgv` but not handled in Main)

**When:** `Main.main` pattern-matches the final Result

**Then:** `Gitlab::Fp::UnmatchedResultError` is raised

---

## 7. Argument Parsing Scenarios

### args: unknown option

**When:** `scripts/ai_harness/doctor --unknown`

**Then:** Error message printed to stderr (includes "Unknown option: --unknown"
and the help text), exit code 1, no checks run. `ParseArgv` returns
`Result.err(Messages::InvalidArguments)` with `stderr_text` containing
both the error and the help text.

### args: --fix and --help together

**When:** `scripts/ai_harness/doctor --fix --help`

**Then:** Help text printed to stdout, exit code 0, no checks run. `--help`
takes precedence over `--fix`. `ParseArgv` sets `print_help: true`.

### args: no arguments (default)

**When:** `scripts/ai_harness/doctor`

**Then:** `ParseArgv` adds `fix: false, print_help: false` to context.
`HandleAction` delegates to `PerformDoctorChecks` sub-chain.
