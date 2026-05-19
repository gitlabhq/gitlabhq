# AI Harness Doctor — Agent Instructions

The `ai_harness/doctor` tool lints AI instruction file conventions across the
GitLab monorepo. This file scopes context to that tooling only. For broader
GitLab monorepo conventions, see the top-level `AGENTS.md`.

## Quick Start

```shell
# Run the doctor checks against the real repo
scripts/ai_harness/doctor

# Auto-repair fixable problems (parity and gitignore)
scripts/ai_harness/doctor --fix

# Print help
scripts/ai_harness/doctor --help

# Run the test suite (fast; no Rails boot)
bin/rspec spec/tooling/ai_harness/doctor/

# Run just the integration tests
bin/rspec spec/tooling/ai_harness/doctor/integration_spec.rb

# Run just the unit tests for a specific step
bin/rspec spec/tooling/ai_harness/doctor/steps/perform_doctor_checks/check_parity_spec.rb
```

## SPECIFICATION — Source of Truth

The `tooling/ai_harness/doctor/SPECIFICATION/` directory is the authoritative
source of truth for this tool's design, contracts, and constraints. **Before
making any changes, read the relevant SPECIFICATION files.**

| File | What it covers |
|------|----------------|
| `00_process.md` | Development workflow, TDD cycle, iteration prompt, drift cleanup process and prompt |
| `01_intent.md` | Problem statement, design principles, what it validates, architecture overview |
| `02_contracts.md` | CLI interface, context hash shape, step method signatures, message types, file system contract |
| `03_constraints.md` | Code quality, type safety, functional patterns, error handling, testing rules |
| `04_scenarios.md` | Concrete test scenarios and expected behavior (given/when/then) |

## Sync Mandate

**SPECIFICATION and code must stay in sync at all times.**

- When you **change doctor code** (add/modify/remove a check, step, contract,
  or constraint): update the relevant SPECIFICATION file(s) to reflect the
  change. Use `03_constraints.md §8` as a guide for which file owns which detail.
- When you **change SPECIFICATION** (correct an error, add a scenario, refine a
  contract): ensure the implementation matches. Run specs and the doctor tool
  to verify.
- If you find SPECIFICATION and code out of sync: fix both in the same commit.

## What This Tool Does

The doctor script validates four conventions enforced across the monorepo:

| Check | Description | Auto-fixable? |
|---|---|---|
| **CLAUDE.md / AGENTS.md parity** | Every directory with either file must have both, with identical content. `AGENTS.md` is the source of truth. Symlinks are forbidden — both must be regular files. | ✅ `--fix` copies AGENTS.md → CLAUDE.md |
| **.ai/ reference resolution** | Every `.ai/<path>` reference in any `AGENTS.md` must point to an existing file. | ❌ Must create missing files manually |
| **.gitignore coverage** | Root `.gitignore` must contain `CLAUDE.local.md` and `.ai/*` as non-rooted entries. | ✅ `--fix` appends missing entries |
| **Forbidden committed files** | Tool-specific config (`.claude/`, `.opencode/`, `.gitlab/duo/chat-rules.md`, `*.local.md`) must never be tracked by git. | ❌ Hard fail — remove and `git rm --cached` |

For full details on each check — including parity rules, forbidden file list,
and fixability behavior — see `01_intent.md §2` and `02_contracts.md §3`.

## File Layout

```
tooling/ai_harness/                 ← harness-wide
  config.yml                        runtime config (allowed_committed_files allowlist; future harness-wide keys go here)

tooling/ai_harness/doctor/          ← implementation
  AGENTS.md                         agent instructions (this file; CLAUDE.md is identical)
  CLAUDE.md                         copy of AGENTS.md (parity convention)
  main.rb                           top-level ROP chain (AiHarness::Doctor::Main.main)
  messages.rb                       Gitlab::Fp::Message subclasses
  steps/
    parse_argv.rb                   validates ARGV, sets fix:/print_help: in context
    handle_action.rb                dispatches --help vs. doctor-check path
    help_text.rb                    CLI usage string (used by parse_argv + handle_action)
    print_stdout.rb                 inspect_ok side effect: prints stdout_text
    print_stderr.rb                 inspect_err side effect: prints stderr_text
    perform_doctor_checks/
      main.rb                       sub-chain: runs all four checks
      resolve_repo_root.rb          git rev-parse --show-toplevel → context[:repo_root]
      load_config.rb                loads `tooling/ai_harness/config.yml` → context[:config]
      check_parity.rb               CLAUDE.md/AGENTS.md parity check (fixable)
      check_ai_references.rb        .ai/ reference resolution check (not fixable)
      check_gitignore.rb            .gitignore coverage check (fixable)
      check_forbidden_files.rb      forbidden tracked files check (not fixable)
      format_output.rb              formats context[:results] → context[:stdout_text]
      determine_exit_code.rb        0 if no FAILs, 1 if any FAIL

scripts/ai_harness/doctor           ← thin entrypoint (requires main.rb, calls Main.main)

spec/tooling/ai_harness/doctor/     ← tests (mirrors tooling/ structure)
  integration_spec.rb               end-to-end scenarios using a tmpdir git repo
  main_spec.rb                      unit tests for Main.main ROP chain
  messages_spec.rb                  unit tests for message types
  steps/
    parse_argv_spec.rb
    handle_action_spec.rb
    help_text_spec.rb
    print_stdout_spec.rb
    print_stderr_spec.rb
    perform_doctor_checks/
      main_spec.rb
      resolve_repo_root_spec.rb
      load_config_spec.rb
      check_parity_spec.rb
      check_ai_references_spec.rb
      check_gitignore_spec.rb
      check_forbidden_files_spec.rb
      format_output_spec.rb
      determine_exit_code_spec.rb

tooling/ai_harness/doctor/SPECIFICATION/   ← living specification (source of truth)
  00_process.md
  01_intent.md
  02_contracts.md
  03_constraints.md
  04_scenarios.md
```

## Writing and Extending Checks

Read `00_process.md` for the full TDD iteration cycle. The short version:

1. **Read SPECIFICATION first.** Understand the contracts and constraints before
   writing code.
2. **Update SPECIFICATION if needed.** If a check requires new scenarios or
   changes a contract, update the spec files first.
3. Each check class lives under `AiHarness::Doctor::Steps::PerformDoctorChecks`
   with a single public class method `def self.check(context)`:
   - Destructure via rightward assignment (see `02_contracts.md §2.1`)
   - Run validation; append to `context[:results]`
   - If fixable: check `fix` flag, apply fix, use `"FIXED"` status
   - Return `context`
4. Register the new check in `steps/perform_doctor_checks/main.rb` via
   `.map(YourCheck.method(:check))`.
5. Add unit tests and integration scenarios. All scenarios in `04_scenarios.md`
   must be covered.
6. **Update SPECIFICATION** to reflect what you added.

For code-level constraints (type safety, functional patterns, ROP chain rules,
testing requirements), see `03_constraints.md`.

## Parity Convention

Per the repo root's AI instruction conventions: `AGENTS.md` is the source of
truth, and `CLAUDE.md` must be identical in content (not a symlink). This
convention is enforced by the doctor's own parity check — which means **this
file (`tooling/ai_harness/doctor/AGENTS.md`) and its copy
(`tooling/ai_harness/doctor/CLAUDE.md`) must always have identical
content**. Run `scripts/ai_harness/doctor --fix` to sync them automatically.
