---
name: testing-unit
description: Write, run, and interpret tests for one component or behavior using TDD. Use the applicable framework profile; do not use for live-service contracts or full-system validation.
---

# Unit Testing

Resolve `{Root_Folder}` and any test folders or commands from global project instructions.
Load supplied Markdown language or framework profiles before choosing syntax or commands.
For Nextflow implementation plans and their reference implementations, also load
[Nextflow component testing](./nextflow.md).

## TDD evidence

- **RED:** run the relevant existing tests and record the baseline; if none exist, report that
  instead of claiming a green baseline. Create or extend the smallest focused test and run it.
  The failure must demonstrate missing behavior. A missing production symbol may be valid RED; invalid
  syntax, fixtures, or setup are not.
- **GREEN:** implement the minimum behavior and run the targeted test plus the relevant fast
  suite.
- **REFACTOR:** change structure without behavior changes and keep the targeted and relevant
  suites green after each step.

Keep tests deterministic, independent, and focused on observable behavior. For ordinary unit
tests, isolate network, database, filesystem, time, and process boundaries with suitable test
doubles unless the framework profile requires real execution to verify the component.
Choose reference outputs, property assertions, or both according to
the contract; expected behavior must be independent of the implementation under test.
Report the command, result, covered behavior, and any unresolved failure.
