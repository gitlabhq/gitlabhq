# Doctor Script — Constraints

## Table of Contents

1. [Code Quality](#1-code-quality)
2. [Type Safety](#2-type-safety)
   1. [Type Checking via YARD and Rightward Assignment](#21-type-checking-via-yard-and-rightward-assignment)
   2. [Union Types via Messages Module](#22-union-types-via-messages-module)
   3. [Pattern Matching with Types](#23-pattern-matching-with-types)
   4. [Null Safety](#24-null-safety)
3. [Functional Patterns](#3-functional-patterns)
   1. [Immutable State](#31-immutable-state)
   2. [Pure Functions](#32-pure-functions)
   3. [Higher Order Functions](#33-higher-order-functions)
   4. [Error Handling via ROP](#34-error-handling-via-rop)
4. [Testing](#4-testing)
5. [Fixability Rules](#5-fixability-rules)
6. [Performance](#6-performance)
7. [Compatibility](#7-compatibility)
8. [SPECIFICATION File Responsibilities](#8-specification-file-responsibilities)

---

## 1. Code Quality

- All code uses `frozen_string_literal: true`
- All code lives under the `AiHarness::Doctor` namespace
- ROP pattern follows conventions documented in `ee/lib/remote_development/README.md`
- No Rails dependencies — script must work standalone
- Entrypoint (`scripts/ai_harness/doctor`) is a thin wrapper (see
  `01_intent.md` §3.3 for the code). **No other logic** in the entrypoint.
- **`Main` must be a dumb router.** The `Main` class contains exactly one
  method: `main`. No private helpers, no other class methods. See
  `02_contracts.md` §2.2 for the signature and behavior. **All domain
  logic** — argument parsing, validation, business rules, output
  formatting, exit code determination, stdout output, and infrastructure
  operations (e.g., resolving the repo root via git) — must live in step
  classes under `steps/`. `Main.main` contains no conditionals beyond the
  pattern match on the Result type. This is a **hard constraint**.
  Rationale: any logic in Main that can fail (e.g., ARGV validation) would
  bypass the ROP error-handling chain and force Main to handle user-facing
  error communication directly, violating the ROP pattern. By keeping Main
  as a dumb router and pushing all domain logic into step classes, every
  possible outcome is handled uniformly through the chain.
- **`private_class_method` declarations must be listed at the end of the
  class**, not inline on `def self.` method definitions. This follows the
  convention used in `ee/lib/remote_development/`. Define methods normally,
  then declare `private_class_method :method_a, :method_b` before the
  closing `end` of the class.

---

## 2. Type Safety

The doctor script leverages type safety where possible and pragmatic,
following the principle of being **"as type safe as profitable"**.

### 2.1 Type Checking via YARD and Rightward Assignment

- Use YARD annotations for method signatures where they provide value
  (particularly on public API methods like `Main.main` and step `.check`
  methods).
- Use Ruby rightward assignment pattern matching with type assertions for
  all context hash access. This provides runtime type checking without
  requiring RBS or Sorbet.

Example — destructuring context in a step:

```ruby
def self.check(context)
  context => {
    repo_root: String => repo_root,
    fix: (TrueClass | FalseClass) => fix,
    results: Array => results
  }
  # repo_root is guaranteed to be a String here
  # fix is guaranteed to be a boolean
  # If any type doesn't match, NoMatchingPatternError is raised
  # If any key is missing, NoMatchingPatternKeyError is raised
end
```

**Note on error types:** `NoMatchingPatternError` is raised when a value
does not match the expected type in a pattern. `NoMatchingPatternKeyError`
(a subclass) is raised when a required key is missing from the hash. Both
are desirable runtime safety checks and should NOT be rescued — they
indicate bugs in the code.

### 2.2 Union Types via Messages Module

The `Messages` module simulates a union type in Ruby. Each message class
is a constant defined in the module, all inheriting from
`Gitlab::Fp::Message`. This allows exhaustive pattern matching on Result
types (see `02_contracts.md` §2.2 for the canonical pattern match block
and §2.4 for the message type table).

The `else` clause with `UnmatchedResultError` is **mandatory** on every
`case ... in` match. This ensures that if a new message type is added but
not handled, it fails loud at runtime instead of silently falling through.

### 2.3 Pattern Matching with Types

- Use `case ... in` for pattern matching on Result types with exhaustive
  matching (mandatory `else` raising `UnmatchedResultError`).
- Use rightward assignment (`context => { key: Type => var }`) for
  destructuring hashes with type assertions.
- Prefer pattern matching over `#dig` or `#[]` for hash access — pattern
  matching raises descriptive `NoMatchingPatternKeyError` on missing keys
  instead of returning nil.
- `#deconstruct_keys` must be implemented on any custom value objects used
  in pattern matching.

### 2.4 Null Safety

- Never use `Hash#[]` or `#dig` to access hash keys in the context —
  both return nil on missing keys, hiding bugs.
- Use `#fetch` or rightward assignment pattern matching, both of which
  raise on missing keys.
- Prefer rightward assignment over `#fetch` where the hash structure is
  known, as it provides both null safety and type safety in a single
  expression.

---

## 3. Functional Patterns

The doctor script follows functional programming patterns.

### 3.1 Immutable State

- Use immutable state wherever possible. This leads to fewer state-related
  bugs and code which is easier to understand, test, and debug.
- The one exception is the mutable context Hash passed along the ROP chain.
  Mutating the context (e.g., appending to `results`) is acceptable per the
  the ROP chain convention, because the ROP chain architecture makes it
  safe — each step processes sequentially, and the context flows in one
  direction.
- Do not mutate any other objects passed through the chain.

### 3.2 Pure Functions

- All business logic lives in class (singleton) methods. No instance
  variables, no constructors, no mutable class state.
- This intentionally prevents holding onto mutable state in the class,
  resulting in classes that are easier to debug and test.
- Instance variables are a form of state incompatible with pure functions.
  They are not used in step classes or the Main class.
- Internal helper methods (private class methods) may have individual
  keyword arguments for their dependencies — only the public API method
  uses the context Hash.
- **Steps do NOT perform IO** to stdout, stderr, or any output stream.
  Steps produce data in the context hash; stdout is handled by
  `PrintStdout` via `inspect_ok`, stderr by `PrintStderr` via
  `inspect_err` (see `02_contracts.md` §2.2). The one exception to the
  no-IO rule is `--fix` mode: fixable check steps (parity, gitignore)
  write files as a side effect when `fix: true`. This is an inherent
  requirement of the fixability rules (see §5) and is the documented
  exception to the pure functions constraint.
- This rule is also why harness-wide configuration is loaded by a
  dedicated step (`LoadConfig`) into `context[:config]` rather than via
  a class-level memoized accessor: a memoized class-method accessor is
  exactly the "mutable class state" the rule prohibits.

### 3.3 Higher Order Functions

- The ROP chain uses `Method` objects (via `.method(:check)`) as higher
  order functions passed to `Result#and_then`, `Result#map`,
  `Result#inspect_ok`, and `Result#inspect_err`.
- Do not use procs. Only lambdas and class/singleton `Method` objects are
  acceptable, because of proc's surprising behavior with `return` and
  argument arity.

### 3.4 Error Handling via ROP

- The Railway Oriented Programming pattern using `Gitlab::Fp::Result`
  handles all expected error cases as domain messages.
- **`--help` is NOT an error.** It is handled on the ok path via
  `context[:print_help]`. `HandleAction` checks this flag and either
  sets help text directly or delegates to the `PerformDoctorChecks`
  sub-chain.
- **`Steps::ParseArgv`** may return `Result.err` for invalid arguments
  only. This short-circuits the chain — no further steps run.
  `ParseArgv` is the only step chained via `.and_then`.
- **Sub-chain pattern.** `HandleAction` delegates to
  `PerformDoctorChecks::Main` as a sub-chain, following the precedent
  in `ee/lib/remote_development/workspace_operations/create/creator.rb`
  which calls `DesiredConfig::Main.method(:main)` via `.map`. The
  sub-chain receives the parent context, runs its own chain, sets
  results in the parent context, and returns it.
- **Check steps, `FormatOutput`, and `DetermineExitCode` are infallible.**
  They are chained via `.map` within the sub-chain (see
  `02_contracts.md` §2.3 for return type details). All checks always
  run — there is no short-circuiting on individual check failures.
- Unexpected errors (bugs, infrastructure failures) are NOT caught —
  they propagate as exceptions. Only invalid arguments become a domain
  message. Check pass/fail status is data in the context, not a Result
  err.
- **Git subprocess failures must be detected.** Every `Open3.capture3`
  call to `git` must check `status.success?` on the returned status
  object and raise if the subprocess failed. Without this, a failed
  `git ls-files` returns an empty string, causing checks to report
  false "OK". Similarly,
  `Steps::PerformDoctorChecks::ResolveRepoRoot.resolve` must check
  `status.success?` and raise if `git rev-parse` fails or returns an
  empty string.
- Short-circuiting occurs only at `ParseArgv` (invalid args). Both
  `.and_then` and `.map` pass through `Result.err` unchanged, so a
  `ParseArgv` err skips all subsequent steps.

### 3.5 No Symlinks for Instruction Files

Neither `AGENTS.md` nor `CLAUDE.md` may be a symlink at any directory level.
Symlinks between the two files would silently satisfy the parity check
while behaving differently across platforms and tools (some follow
symlinks, some don't). The parity check detects symlinks before
checking content and reports them as issues.

In `--fix` mode, a symlinked file is replaced with a regular file
containing the symlink target's content (read → delete → write). This
preserves the content while eliminating the symlink.

### 3.6 .ai/ Reference Resolution

`.ai/` references extracted from an `AGENTS.md` file are resolved **relative
to the directory containing that `AGENTS.md` file**, not relative to the
repo root. This allows directories containing `AGENTS.md` to be moved without
breaking their `.ai/` references.

For example:
- `AGENTS.md` at `sub/AGENTS.md` referencing `.ai/git.md` resolves to
  `sub/.ai/git.md`
- `AGENTS.md` at `AGENTS.md` (repo root) referencing `.ai/git.md` resolves
  to `.ai/git.md` (same as repo root, since root `AGENTS.md` lives at the
  repo root)

---

## 4. Testing

- All specs use `fast_spec_helper`, never `spec_helper` or `rails_helper`
- Unit tests must have 100% line and branch coverage
- Unit tests use mocks liberally, following
  ROP mocking patterns from `ee/spec/lib/remote_development/` for loose coupling
- **Use `Gitlab::Fp` RSpec helpers wherever possible.** Specs that assert
  on `Result` objects must use the `ResultMatchers` helpers (`be_ok_result`,
  `be_err_result`) from `spec/support/matchers/result_matchers.rb` instead
  of manually calling `.ok?`/`.err?`/`.unwrap`/`.unwrap_err`. Since specs
  use `fast_spec_helper`, the matchers must be required explicitly and
  included in the spec via `include ResultMatchers`. See
  `ee/spec/lib/remote_development/` for canonical usage examples.
- Main spec verifies step invocation order and ROP chain wiring using
  ordered message expectations. (The `invoke_rop_steps` matcher from
  `spec/support/matchers/invoke_rop_steps.rb` is designed for steps that
  return `Result` objects via `.and_then`; it does not fit check steps
  that return context hashes via `.map`.)
- Integration spec uses tmpdir simulated filesystem with real `git init`
  (for `git ls-files` to work)
- Integration spec is structured with top-level contexts:
  `"happy path"`, `"error cases"`, `"--fix mode"`
- Strict TDD: failing test first, then minimal implementation
- `gdk predictive --yes` must pass before pushing. It must run **after**
  committing — it compares committed changes against `master`, so
  uncommitted/untracked files are invisible to it.

---

## 5. Fixability Rules

| Check | Fixable? | Fix behavior |
|-------|----------|-------------|
| Parity (missing/differs) | Yes | Copy AGENTS.md → CLAUDE.md (or create missing file) |
| Parity (symlink) | Yes | Replace symlink with a regular file copy of target content |
| .ai/ references | No | Missing files must be created manually |
| .gitignore | Yes | Append missing entries |
| Forbidden files | No | Hard fail. User must remove/gitignore |

---

## 6. Performance

- Directory globbing must skip `.git/`, `node_modules/`, `vendor/`, `tmp/`
- `git ls-files` is used for forbidden file detection (efficient, respects
  git state)

---

## 7. Compatibility

- Must work in the GitLab monorepo on macOS and Linux
- No gem dependencies beyond what ships with Ruby stdlib and the existing
  `lib/gitlab/fp/` module

---

## 8. SPECIFICATION File Responsibilities

Each SPECIFICATION file has a distinct role. When updating the
SPECIFICATION, place details in the correct file and do not duplicate
specific information across files.

| File | Role | Contains |
|------|------|----------|
| `00_process.md` | How to develop | Iteration cycle, TDD workflow, verification steps, implementation prompt |
| `01_intent.md` | Why and what | Problem statement, design principles, what it validates, architecture overview (chain snippet, namespace, entrypoint), acceptance-level definition of done |
| `02_contracts.md` | Precise interfaces | CLI interface, context hash shape, step method signatures, message types, file system contract |
| `03_constraints.md` | Rules and invariants | Code quality, type safety, functional patterns, error handling, testing rules, fixability, performance, compatibility |
| `04_scenarios.md` | Expected behaviors | Given/when/then scenarios organized by check and category |

**Rules:**
- **No duplication of specifics.** A specific detail (e.g., step return
  types, context hash keys, pattern match examples) should live in exactly
  one file. Other files may reference it (e.g., "see `02_contracts.md`
  §2.3") but must not repeat it.
- **`01_intent.md` may summarize general patterns** (e.g., "the chain uses
  `.and_then` and `.map`") but must not explain their semantics — that
  belongs in `03_constraints.md`.
- **`01_intent.md` may contain code snippets** (chain, entrypoint) as
  architectural illustrations, but detailed contracts for those snippets
  belong in `02_contracts.md`.
- **Definition of Done in `01_intent.md`** lists acceptance criteria
  verified against the running system. Code-level constraints are not
  repeated there — instead, a blanket item references `03_constraints.md`.
