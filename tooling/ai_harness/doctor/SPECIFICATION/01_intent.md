# Doctor Script — Intent

## Table of Contents

1. [Overview and Goals](#1-overview-and-goals)
   1. [Problem Statement](#11-problem-statement)
   2. [Design Principles](#12-design-principles)
2. [What It Validates](#2-what-it-validates)
   1. [CLAUDE.md / AGENTS.md Parity](#21-claudemd--agentsmd-parity)
   2. [.ai/ Reference Resolution](#22-ai-reference-resolution)
   3. [.gitignore Coverage](#23-gitignore-coverage)
   4. [Forbidden Committed Files](#24-forbidden-committed-files)
3. [Architecture](#3-architecture)
   1. [Namespace and File Layout](#31-namespace-and-file-layout)
   2. [ROP Chain Design](#32-rop-chain-design)
   3. [Entrypoint](#33-entrypoint)
4. [Definition of Done](#4-definition-of-done)

---

## 1. Overview and Goals

### 1.1 Problem Statement

AI coding tools (Claude Code, OpenCode, Duo) each look for their own
configuration files. Without guardrails, contributors could commit
tool-specific files (`.claude/rules/`, `.opencode/` configs, skills, hooks)
that impose tooling choices on all contributors. The doctor script prevents
this while still allowing the instruction markdown files that benefit everyone.

The `scripts/ai_harness/doctor` script validates that AI agent instruction
files in the GitLab monorepo follow the project's conventions. It reports
per-check status and supports `--fix` to auto-repair fixable issues.

It enforces the principle that **only markdown instruction files** should be
committed to the repo — no skills, hooks, commands, agents, or tool-specific
configuration files. Users retain full control over their own tooling
configuration via gitignored local files.

See: https://gitlab.com/gitlab-org/gitlab/-/work_items/594821

### 1.2 Design Principles

1. **Markdown-only committed files.** The repo commits only `.md` instruction
   files. All tool-specific configuration (skills, hooks, settings, agents) is
   gitignored and stays local.

2. **Tool-agnostic parity.** `AGENTS.md` (tool-agnostic) and `CLAUDE.md`
   (Claude Code specific) must always have identical content at every directory
   level. `AGENTS.md` is the source of truth; the doctor copies it to
   `CLAUDE.md` during `--fix`.

3. **No Rails dependency.** The doctor script must work standalone — no
   `require 'rails_helper'`, no ActiveRecord, no application boot. It uses
   only Ruby stdlib and `lib/gitlab/fp/`.

4. **Railway Oriented Programming.** The script follows the ROP pattern
   using `Gitlab::Fp::Result` and `Gitlab::Fp::Message` with conventions
   for context passing, step composition, and message matching. See
   `ee/lib/remote_development/README.md` for the full ROP pattern reference.

5. **Type safety through pattern matching.** All context hash access uses
   Ruby rightward assignment pattern matching with type assertions, following
   the ROP pattern matching conventions. This catches type errors
   at runtime instead of silently propagating nils.

6. **Pure functions and stateless classes.** All step classes use class
   (singleton) methods only. No instance variables, no constructors, no
   mutable state. Each step is a pure function from context → Result.
   Steps do NOT perform IO — they accumulate data in the context hash.
   (Exception: `--fix` mode steps write files; see `03_constraints.md` §3.2.)

7. **Fail loud on unexpected state.** Unmatched Result types raise
   `Gitlab::Fp::UnmatchedResultError`. Missing hash keys raise
   `NoMatchingPatternKeyError`. Type mismatches in rightward assignment
   raise `NoMatchingPatternError`. The script never silently swallows errors.

8. **Fixable vs. unfixable.** Each check declares whether it is auto-fixable.
   `--fix` repairs what it can and reports what it cannot. Forbidden committed
   files are always a hard fail.

---

## 2. What It Validates

The doctor script runs four checks, in order:

### 2.1 CLAUDE.md / AGENTS.md Parity

At every directory level where either file exists, both must exist and have
identical content. `AGENTS.md` is the source of truth for `--fix` operations.
When only `CLAUDE.md` exists (no `AGENTS.md`), `--fix` creates `AGENTS.md`
from `CLAUDE.md`.

### 2.2 .ai/ Reference Resolution

Every `AGENTS.md` file in the repo (root and subdirectories) is scanned.
All `.ai/*` references found must resolve to existing files. References are
extracted via regex matching `.ai/` path patterns. This check is not
auto-fixable — missing files must be created manually.

**Design note — `@` prefix convention:** The `@` prefix in instruction
files forces AI tools to eagerly read the referenced file on load.
`CLAUDE.local.md` is the only file referenced this way
(`@CLAUDE.local.md`). All `.ai/` module references use plain paths (no `@`)
so agents read them on demand based on task context.

**Implementation note:** The doctor's regex extracts `.ai/` paths without
the `@` prefix, since `.ai/` references never use it.

### 2.3 .gitignore Coverage

The root `.gitignore` must contain non-rooted entries for `CLAUDE.local.md`
and `.ai/*` to ensure user local files are properly ignored at all directory
levels. `--fix` appends missing entries. Note: committed instruction files
(like `AGENTS.md`) must be force-added (`git add --force`) since the
gitignore patterns are non-rooted.

### 2.4 Forbidden Committed Files

No tool-specific configuration files (`.claude/`, `.opencode/`,
`.gitlab/duo/`) may be in a staged or committed state. These files in a
gitignored state are fine — this check uses `git ls-files` to detect only
staged/committed state. This is a hard fail, not fixable with `--fix`.

See `02_contracts.md` §3.3 for the complete forbidden files list.

---

## 3. Architecture

### 3.1 Namespace and File Layout

- **Namespace:** `AiHarness::Doctor::`
- **Entry point:** `tooling/ai_harness/doctor/main.rb` contains the top-level
  ROP chain
- **Steps:** Each step is a decoupled class under
  `tooling/ai_harness/doctor/steps/`. Doctor check steps live in a
  sub-chain under `tooling/ai_harness/doctor/steps/perform_doctor_checks/`.
- **Messages:** All Result context types are defined in
  `tooling/ai_harness/doctor/messages.rb` as `Gitlab::Fp::Message` subclasses

### 3.2 ROP Chain Design

The ROP chain is the core of the script. `Main.main` builds a minimal
initial context, wraps it in `Result.ok`, and chains all steps.

Example illustrating the chain style (actual steps may differ and evolve):

```ruby
result =
  Gitlab::Fp::Result.ok(context)
    .and_then(Steps::SomeStep.method(:call))           # and_then: may short-circuit with Result.err
    .map(Steps::AnotherStep.method(:call))              # map: always continues, transforms context
    # ... additional steps chained here
    .inspect_ok(Steps::PrintStdout.method(:print))      # inspect_ok: stdout side effect for ok path
    .inspect_err(Steps::PrintStderr.method(:print))     # inspect_err: stderr side effect for err path
```

Each step receives the context hash and returns a Result. The chain uses
`.and_then` for steps that may short-circuit (e.g., invalid args),
`.map` for steps that always continue, and
`.inspect_ok`/`.inspect_err` for IO side effects (stdout and stderr
respectively). A `.map` step may delegate to a sub-chain (see
`02_contracts.md` §2.3 for the `PerformDoctorChecks` sub-chain).
See `02_contracts.md` for the context hash shape, step signatures, and
message types. See `03_constraints.md` for chain operator semantics and
error handling rules.

### 3.3 Entrypoint

`scripts/ai_harness/doctor` is a thin wrapper that requires the main
module and delegates to `Main.main`, exiting with its return code.
All logic lives under `tooling/ai_harness/doctor/`.

See `03_constraints.md` §1 for the `Main.main` dumb router constraint.

---

## 4. Definition of Done

These are acceptance criteria verified against the running system. For
code-level constraints (type safety, functional patterns, testing rules),
see `03_constraints.md`.

- All four checks implemented and passing against the real repo
- `--fix` mode correctly repairs parity and gitignore issues
- `--help` prints usage and exits 0
- `scripts/ai_harness/doctor` runs clean against the real repo (exit 0)
- All scenarios in `04_scenarios.md` pass
- All constraints in `03_constraints.md` are satisfied
- `gdk predictive --yes` passes
