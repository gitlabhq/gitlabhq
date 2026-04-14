# AI Harness Doctor

The `doctor` script validates that AI agent instruction files in the GitLab
monorepo follow the project's conventions. See the
[SPECIFICATION](SPECIFICATION/01_intent.md) for details on what it validates.

## Usage

```shell
scripts/ai_harness/doctor          # validate the repo
scripts/ai_harness/doctor --fix    # auto-repair fixable issues
scripts/ai_harness/doctor --help   # print usage
```

## File layout

| Path | Purpose |
|------|---------|
| `main.rb` | ROP chain entry point (`AiHarness::Doctor::Main.main`) |
| `messages.rb` | `Gitlab::Fp::Message` subclasses for Result types |
| `steps/` | One step class per check (parse argv, resolve repo root, each validation, format output) |
| `SPECIFICATION/` | Living specification documents that drive implementation |

## About the specification-driven approach

The `SPECIFICATION/` directory contains structured documents that define the
script's intent, contracts, constraints, and scenarios. Implementation is
driven iteratively from these specs using strict TDD.

**This is an experiment.** The spec-driven style was chosen for this
particular script as an exploration of how well the approach works for
AI-assisted development. Its presence in the GitLab repository should not be
interpreted as a standard, recommendation, or pattern that other code must
adopt or follow. The approach may change, evolve, or be removed entirely in
the future.

The specification files are:

- `00_process.md` — development workflow, iteration cycle, ready-to-use
  prompts for AI-assisted spec-driven development and drift cleanup
- `01_intent.md` — problem statement, design principles, what the script validates
- `02_contracts.md` — context hash shapes, step signatures, message types
- `03_constraints.md` — code-level rules (type safety, testing, error handling)
- `04_scenarios.md` — concrete test scenarios and expected behavior
