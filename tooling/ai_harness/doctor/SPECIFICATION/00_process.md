# Doctor Script — Development Process

## Overview

The doctor script is developed using a specification-driven iterative process.
The SPECIFICATION directory (this directory) is the source of truth for all
implementation decisions.

## Iterative Implementation Process

Each iteration of the implementation follows this cycle:

1. **Implement** — Use the SPECIFICATION to drive the next increment of
   implementation. Use strict TDD: write failing tests first, then implement
   minimal code to pass. Work top-down from Main. Follow all testing rules
   in `03_constraints.md` §4.

2. **Verify locally**
    1. Run specs (`ENABLE_SPRING=1 bin/rspec spec/tooling/ai_harness/doctor/ --format documentation`)
    2. Run `scripts/ai_harness/doctor` against the repo, and ensure it passes.

3. **Update SPECIFICATION** — If implementation reveals problems, ambiguities,
   or missing details in the SPECIFICATION, update the relevant spec files
   directly. The SPECIFICATION is a living document.

4. **Commit** — Commit the implementation increment (and any spec updates).

5. **Run `gdk predictive --yes`** — This must run **after** committing,
   because it compares committed changes against `master`. Untracked or
   unstaged files are invisible to it. If it fails, fix the issues, amend
   the commit, and re-run.

6. **Repeat** — Continue until all scenarios in `04_scenarios.md` pass and
   all constraints in `03_constraints.md` are satisfied.

At some point the implementation is ready for MR review. Review feedback feeds
back into the SPECIFICATION, and the iteration continues through merge.

## Drift Cleanup Process

After any significant change (implementation, SPECIFICATION update, or review
feedback), make a dedicated pass to verify that **all markdown files** are
consistent with the current implementation. This includes:

- `SPECIFICATION/` files (01–04) — do they accurately describe the current
  contracts, constraints, scenarios, and architecture?
- `AGENTS.md` / `CLAUDE.md` (in `spec/tooling/ai_harness/doctor/`) — does the
  file layout, architecture description, and check table match the implementation?
- `tooling/ai_harness/doctor/README.md` — does it accurately describe usage,
  options, and behavior?
- Any other documentation that references the doctor tool.

The goal is to catch drift introduced by incremental changes where the
implementation evolves but the surrounding documentation lags behind.

### Drift Cleanup Prompt

Use the following prompt after completing implementation work to clean up
any drift:

~~~
Read all the markdown files related to the doctor tool:
- tooling/ai_harness/doctor/SPECIFICATION/ (all files)
- tooling/ai_harness/doctor/README.md
- spec/tooling/ai_harness/doctor/AGENTS.md (and its identical copy CLAUDE.md)

Then read the current implementation:
- tooling/ai_harness/doctor/ (all .rb files)
- spec/tooling/ai_harness/doctor/ (all spec files)
- scripts/ai_harness/doctor (entrypoint)

Compare the markdown documentation against the actual implementation.
Look for:
1. File layout descriptions that don't match reality (missing/extra files,
   wrong paths, wrong descriptions)
2. Architecture descriptions that don't match the actual ROP chain in main.rb
3. Check descriptions (names, fixability, behavior) that don't match the
   implementation
4. Contract or constraint descriptions that diverge from code
5. Scenarios that are not covered by integration tests, or integration tests
   that cover scenarios not documented in 04_scenarios.md

Fix any inconsistencies you find. Update documentation to match code — not
the other way around (code is truth, docs describe it). Ensure AGENTS.md
and CLAUDE.md remain identical after any edits.

Report what you found and fixed.
~~~

## Implementation Prompt

Use the following prompt to drive each iteration:

~~~
Read the SPECIFICATION files in tooling/ai_harness/doctor/SPECIFICATION/
(01_intent.md, 02_contracts.md, 03_constraints.md, 04_scenarios.md).

Review the current implementation state. Identify what is not yet implemented
or what does not match the SPECIFICATION. See the git history of the SPECIFICATION
directory to understand what changes were made.

Pick the next unimplemented scenario or failing constraint. Using strict TDD:
1. Write a failing unit test for it. Unit test(s) are mandatory.
2. Run the test(s) to confirm it fails.
3. Write minimal implementation to make it pass.
4. Write an integration tests if applicable to cover a significant usability issue
   at the middle/top of the testing pyramid.
5. Run all tests to confirm green.
6. If the SPECIFICATION needs updating based on what you learned, update it.
   When updating, respect the file responsibilities — do not duplicate
   specific details across files (see 03_constraints.md §8).
7. Run `gdk predictive --yes`. This MUST run after staging any unstaged/new files — it compares
   changes against master, so unstaged files are invisible to it.
   If it fails, fix the issues, then re-run. DO NOT AUTOMATICALLY COMMIT.


Report what you implemented, what tests you wrote, and any SPECIFICATION
changes you made.

Then ask the user if they would like you to commit and push.
~~~

## Planning Reference

The planning process that generated this specification is documented at:
https://gitlab.com/cwoolley-gitlab/ai-workflow-artifacts/-/tree/master/workflow-artifacts/workitem-594821

This is a personal repository and may not be accessible to all contributors.
The SPECIFICATION itself is self-contained — the link is for historical
context only.
