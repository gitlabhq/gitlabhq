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

## Error handling philosophy

The doctor follows a "fail loud" model: only invalid CLI arguments are
expected (domain) errors and are handled via the ROP chain. Everything else —
missing repo root, missing or unparseable `config.yml`, missing required
config keys, unexpected context hash shape — propagates as an exception. See
[`SPECIFICATION/03_constraints.md` §3.4](SPECIFICATION/03_constraints.md#34-error-handling-via-rop)
for the contract, and the broader Remote Development error philosophy at
[`ee/lib/remote_development/README.md`](../../../ee/lib/remote_development/README.md#what-types-of-errors-should-be-handled-as-domain-messages)
for the underlying rationale (domain messages are for *expected* errors only;
infrastructure errors and bugs in our own code propagate).

Concretely:

- `YAML.safe_load_file` enforces YAML syntax (parse error → propagates).
- `config.fetch('key')` enforces required-key presence (`KeyError` →
  propagates). We do **not** use `.fetch(key, default)` fallbacks for
  required keys — a missing key in our own internal `config.yml` is a bug,
  not a validation case, and silently defaulting would mask it.
- Pattern destructuring (`config: Hash => config`) enforces top-level type.

Schema validation is intentionally absent for our own internal config files;
the boundary checks above are the contract.

## Review criteria for AI-generated specs

The unit and integration specs under `spec/tooling/ai_harness/doctor/` are
AI-generated and treated as an opaque implementation detail. Reviewers and
the assignee should evaluate them against just two criteria:

1. **Unit-level coverage** — 100% line and branch coverage via SimpleCov.
2. **Integration-level coverage** — full coverage of the scenarios in
   [`SPECIFICATION/04_scenarios.md`](SPECIFICATION/04_scenarios.md).

Beyond those, spec internals (test descriptions, identifier choices,
assertion shape, occasional placeholder-y wording) are intentionally out of
scope for human review on this tooling. The rationale is that this is an
isolated, low-risk, low-blast-radius CLI; spending review cycles on
spec-internal cosmetics is not a good use of time. See
[this discussion](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/229391#note_3237537772)
for the original framing.

These criteria apply only to this tool's specs; they are **not** a
recommendation for the wider GitLab codebase.
