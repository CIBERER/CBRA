---
name: testing-e2e
description: Write, run, and interpret tests through an application's public interface. Use for complete user-visible flows; do not use for isolated units or direct real-service contract checks.
---

# End-to-End Testing

Resolve `{Root_Folder}` and the E2E test location and commands from global project
instructions. Load only the supplied Markdown profiles relevant to the public interface. For a
Go CLI, use [references/go-cli.md](./references/go-cli.md).

Exercise the same entry point a user or external consumer uses. Keep each scenario independent
and assert observable output or state rather than internal calls. Controlled fakes may replace
external systems when the application itself is still exercised end to end; tests against a
real external system belong to `testing-integration`.

For TDD, demonstrate RED for one user-visible behavior, then rerun the same scenario for GREEN
after implementation and REFACTOR. Report the exact command, interface exercised, result, and
any environment limitation.
