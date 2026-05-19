# Doctor Script — Contracts

## Table of Contents

1. [CLI Interface](#1-cli-interface)
2. [ROP Chain Contract](#2-rop-chain-contract)
   1. [Context Hash](#21-context-hash)
   2. [Main.main Signature and Return Value](#22-mainmain-signature-and-return-value)
   3. [Step Method Signatures](#23-step-method-signatures)
   4. [Messages (Union Type)](#24-messages-union-type)
3. [File System Contract](#3-file-system-contract)
   1. [Committed Instruction Files](#31-committed-instruction-files)
   2. [Gitignored User Files](#32-gitignored-user-files)
   3. [Forbidden Files (must NOT be staged/committed)](#33-forbidden-files-must-not-be-stagedcommitted)

---

## 1. CLI Interface

**Invocation:** `scripts/ai_harness/doctor [OPTIONS]`

**Options:**
- `--help` — Print help text, exit 0, do not run checks
- `--fix` — Auto-repair fixable problems

**Exit codes:**
- `0` — All checks passed (or all fixable issues were fixed)
- `1` — One or more checks failed

**Output format:** One line per check:
```
Check: <name> ............ <STATUS>
  <detail line>
  <detail line>
```

Where STATUS is one of: `OK`, `FAIL`, `FIXED`

In `--fix` mode, a single run may produce a mix of all three statuses:
`FIXED` for checks that were repaired, `FAIL` for unfixable problems, and
`OK` for checks that were already passing. The exit code is `1` if any
check has status `FAIL`; `FIXED` checks do not cause a non-zero exit.

---

## 2. ROP Chain Contract

### 2.1 Context Hash

The context hash flows through the ROP chain, accumulating data at each
step. It is designed for destructuring via Ruby rightward assignment pattern
matching.

**Initial context — built by `Main.main`:**

`Main.main` builds a **minimal** context containing only an empty results
accumulator. It does NOT parse ARGV or resolve the repo root — those are
the responsibility of chain steps.

```ruby
context = {
  results: []            # Accumulated check results (Array<Hash>)
}
```

**Added by `Steps::ParseArgv`:**

`ParseArgv` reads `ARGV` directly and validates command-line arguments.
On success, it adds:
```ruby
context[:fix] = true | false           # Whether --fix was requested
context[:print_help] = true | false    # Whether --help was requested
```

If arguments are invalid, `ParseArgv` returns
`Result.err(Messages::InvalidArguments)` — the chain short-circuits and
no further steps run. `--help` is NOT an error; it sets
`print_help: true` on the ok path.

**Added by `Steps::HandleAction` (or its sub-chain):**

`HandleAction` reads `context[:print_help]`. If true, it sets
`stdout_text` and `exit_code: 0` directly (using `HelpText.help`).
If false, it delegates to `Steps::PerformDoctorChecks::Main.main`,
a sub-chain that runs the doctor checks. Either way, after
`HandleAction`:
```ruby
context[:stdout_text] = String    # Text to print to stdout
context[:exit_code] = Integer     # 0 or 1
```

**Within the `PerformDoctorChecks` sub-chain:**

The sub-chain runs when `print_help` is false. It adds to the context:
```ruby
context[:repo_root] = String     # Added by ResolveRepoRoot
context[:config] = Hash          # Added by LoadConfig
context[:stdout_text] = String   # Added by FormatOutput
context[:exit_code] = Integer    # Added by DetermineExitCode
```

`context[:config]` mirrors the shape of `tooling/ai_harness/config.yml`
exactly — hashes/arrays are preserved as-is. Downstream steps read keys
they need from this hash.

`ResolveRepoRoot` and `LoadConfig` raise on failure (git not found, not
in a repo, config file missing or unparseable) — these are
infrastructure errors, not domain errors. Check steps append to
`context[:results]`.

**Important:** The context hash does NOT contain an IO object. Check and
transform steps are pure — no IO side effects. Stdout is handled by
`PrintStdout` via `inspect_ok`, stderr by `PrintStderr` via
`inspect_err` (see §2.2).

**Rightward assignment example in a check step:**

```ruby
def self.check(context)
  context => { repo_root: String => repo_root, fix: (TrueClass | FalseClass) => fix, results: Array => results }
  # ...
end
```

Note: check steps destructure `fix:` — a key that was added by `ParseArgv`
earlier in the chain. The context accumulates entries from each step as
the chain progresses.

Each entry in `:results` is a Hash:
```ruby
{ name: String, status: "OK" | "FAIL" | "FIXED", details: Array<String> }
```

### 2.2 Main.main Signature and Return Value

`Main.main` is a **dumb router** (see `03_constraints.md` §1 for the
rationale and hard constraint). It takes no arguments, builds the initial
context (an empty results accumulator), runs the ROP chain (which handles
all stdout output via `inspect_ok`/`inspect_err`), pattern-matches the
result to extract the exit code, and returns it.

```ruby
# @return [Integer] exit code (0 = success, 1 = failure)
def self.main
```

The entrypoint simply calls `exit AiHarness::Doctor::Main.main`.

The ROP chain ends with `inspect_ok` and `inspect_err` for IO side
effects. `PrintStdout` prints `stdout_text` from the context to stdout.
`PrintStderr` prints `stderr_text` from the message content to stderr.
Both return `nil` (the `inspect_*` contract). The original Result passes
through unchanged, so `Main.main` can then pattern-match it to extract
only the exit code:

```ruby
case result
in { ok: { exit_code: Integer => code } }
  # Normal completion — output already printed by PrintStdout
  code
in { err: Messages::InvalidArguments => message }
  # Error output already printed by PrintStderr
  message.content => { exit_code: Integer => code }
  code
else
  raise Gitlab::Fp::UnmatchedResultError.new(result: result)
end
```

`Steps::PrintStdout` and `Steps::PrintStderr` are step classes — not
methods on `Main`. `PrintStdout` destructures `stdout_text` from the
context and prints to `$stdout`. `PrintStderr` destructures
`stderr_text` from the message's `content` hash and prints to `$stderr`.
Both return `nil`.

### 2.3 Step Method Signatures

#### Top-level chain steps

**`Steps::ParseArgv`** — parses and validates command-line arguments:

```ruby
def self.parse(context) → Gitlab::Fp::Result
```

- Reads `ARGV` directly (not from context)
- If `--help`: adds `print_help: true, fix: false` to context, returns
  `Result.ok(context)`
- If `--fix`: adds `print_help: false, fix: true`, returns
  `Result.ok(context)`
- If no arguments: adds `print_help: false, fix: false`, returns
  `Result.ok(context)`
- If unknown/invalid arguments: returns
  `Result.err(Messages::InvalidArguments.new(content))` where `content`
  is `{ stderr_text: String, exit_code: 1 }`. The `stderr_text`
  includes both the error message and the help text (from `HelpText`).
- `ParseArgv` is the only step chained via `.and_then`.

**`Steps::HandleAction`** — dispatches based on `print_help`:

```ruby
def self.handle(context) → Hash
```

- If `context[:print_help]` is true: sets `context[:stdout_text]` from
  `HelpText.help` and `context[:exit_code] = 0`. Returns `context`.
- If `context[:print_help]` is false: delegates to
  `Steps::PerformDoctorChecks::Main.main(context)` sub-chain, which
  sets `stdout_text` and `exit_code`. Returns `context`.
- **Returns `context`** (the hash, not a Result) — chained via `.map`

**`Steps::PrintStdout`** — stdout IO side effect:

```ruby
def self.print(context) → nil
```

- Destructures `stdout_text` from the context and prints to `$stdout`.
- Chained via `.inspect_ok`.
- Returns `nil` (the `inspect_*` contract).

**`Steps::PrintStderr`** — stderr IO side effect:

```ruby
def self.print(message) → nil
```

- Destructures `stderr_text` from the message's `content` hash and
  prints to `$stderr`.
- Chained via `.inspect_err`.
- Returns `nil` (the `inspect_*` contract).

**`HelpText`** — shared help text (not a step, no context):

```ruby
def self.help → String
```

- Returns the CLI help string. Called by both `ParseArgv` (for invalid
  args error text) and `HandleAction` (for `--help` output).

#### Sub-chain steps (under `Steps::PerformDoctorChecks`)

**`Steps::PerformDoctorChecks::Main`** — sub-chain for doctor checks:

```ruby
def self.main(context) → Hash
```

- Receives the parent context (with `fix:`, `results:`, etc.)
- Runs its own ROP chain: `ResolveRepoRoot` → check steps →
  `FormatOutput` → `DetermineExitCode`
- Sets `context[:stdout_text]` and `context[:exit_code]`
- **Returns `context`** — follows the sub-chain pattern from
  `ee/lib/remote_development/workspace_operations/create/creator.rb`

**`Steps::PerformDoctorChecks::ResolveRepoRoot`**:

```ruby
def self.resolve(context) → Hash
```

- Runs `git rev-parse --show-toplevel` to determine repo root
- Adds `repo_root: String` to context
- Raises `RuntimeError` if git fails or returns empty (infrastructure error)
- **Returns `context`** — chained via `.map`

**`Steps::PerformDoctorChecks::LoadConfig`**:

```ruby
def self.load(context) → Hash
```

- Reads `tooling/ai_harness/config.yml` via `YAML.safe_load_file`
- Adds `config: Hash` to context — the parsed structure preserved as-is
- Raises on infrastructure failure (file missing, parse error). Per
  `03_constraints.md` §3.4 these exceptions are not rescued, matching
  `ResolveRepoRoot`'s treatment of infrastructure errors.
- **Returns `context`** — chained via `.map`

**Check steps** — each has a single public class method:

```ruby
def self.check(context) → Hash
```

- Receives the full context Hash
- Destructures only the keys it directly needs via rightward assignment
- Appends to `context[:results]`
- **Returns `context`** — `.map` wraps it in `Result.ok` automatically

Check steps are infallible. They record pass/fail status in
`context[:results]` and always pass the context forward. This ensures all
checks always run. They are chained via `.map`, which encodes in the chain
structure itself that they cannot fail.

**`Steps::PerformDoctorChecks::FormatOutput`**:

```ruby
def self.format(context) → Hash
```

- Reads `context[:results]` and produces a formatted output string
- Adds `context[:stdout_text]` to the context
- **Returns `context`** — chained via `.map`

**`Steps::PerformDoctorChecks::DetermineExitCode`**:

```ruby
def self.determine(context) → Hash
```

- Reads `context[:results]` and checks if any result has `status: "FAIL"`
- Adds `context[:exit_code]` (0 if no FAILs, 1 if any FAIL) to the context
- **Returns `context`** — chained via `.map`

### 2.4 Messages (Union Type)

All message types are defined in `tooling/ai_harness/doctor/messages.rb`
as subclasses of `Gitlab::Fp::Message`, simulating a union type.

| Message Class | Type | Meaning |
|--------------|------|---------|
| `InvalidArguments` | err | Unknown or invalid CLI arguments; exit 1 |

`--help` is NOT an error — it is handled on the ok path via
`context[:print_help]` (see §2.1). Only `InvalidArguments` uses the err
rail. Its `content` hash contains `{ stderr_text: String, exit_code: Integer }`.

The normal completion path (both `--help` and doctor checks) flows
through as `Result.ok(context)`, with `stdout_text` and `exit_code` in
the context hash. The per-check granularity lives in
`context[:results]`.

Every `case ... in` match on Result types must include an `else` clause that
raises `Gitlab::Fp::UnmatchedResultError`, ensuring exhaustive matching.

---

## 3. File System Contract

### 3.1 Committed Instruction Files

These files are expected to exist in the repo:

- `AGENTS.md` (top-level, and optionally at subdirectory levels)
- `CLAUDE.md` (identical to `AGENTS.md` at the same level)
- `.ai/*.md` (instruction modules referenced via `.ai/...`)
- `.ai/README.md`

### 3.2 Gitignored User Files

These patterns must be in root `.gitignore` (non-rooted):

- `CLAUDE.local.md`
- `.ai/*`

### 3.3 Forbidden Files (must NOT be staged/committed)

- `AGENTS.local.md`
- `**/AGENTS.local.md`
- `CLAUDE.local.md`
- `**/CLAUDE.local.md`
- `.claude/rules/**`
- `.claude/skills/**`
- `.claude/agents/**`
- `.claude/commands/**`
- `.claude/settings.json`
- `.claude/settings.local.json`
- `.claude/settings.local.jsonc`
- `.opencode/**`
- `.gitlab/duo/chat-rules.md`
- `.gitlab/duo/mcp.json`

`CLAUDE.local.md` (at any directory level) is the personal local override
file used by this repo. It is gitignored by the pattern enforced in §3.2,
but the forbidden check catches the case where someone force-adds it with
`git add --force`. This closes the gap where both the gitignore check and
the forbidden check would otherwise pass silently if the gitignore entry
exists but the file is tracked.

`AGENTS.local.md` (at any directory level) is non-standard for this repo
and is not required in `.gitignore`, but is included in the forbidden list
so that any accidental commit (force-added or otherwise) is still caught.

These files in a gitignored or `.git/info/exclude`'d state are acceptable.

**Allowed exceptions within forbidden patterns:**

Files listed in `tooling/ai_harness/config.yml` under the
`allowed_committed_files` key are intentionally committed as project
content and are NOT flagged as forbidden. The `LoadConfig` step loads
this YAML once at the head of the sub-chain into `context[:config]`,
and the forbidden-files check reads the allowlist via
`context[:config].fetch('allowed_committed_files')`.

The YAML uses prefix matching: an entry matches any tracked path that
begins with the entry string. This supports both exact-file paths
(e.g. `.claude/skills/foo/SKILL.md`) and directory prefixes
(e.g. `.claude/skills/foo/`).

Each entry should be preceded by a YAML comment explaining the reason
for the exception.

Initial entries:
- `.claude/skills/gitlab-coding-principles/SKILL.md` (added in !234174)
