# Codex Workflow Catalog

## Delivery Flow

The user-facing sequence is `product_owner` -> human approval -> `builder` -> `dev_ops` when
release or code-documentation work is requested.

`builder` delegates preparation to `engineer` before TDD. The engineer creates the plan and the
applicable ER model. Specification status ownership follows the same flow:

Each work item owns one stable specification file and that specification owns one stable plan.
Revisions update those files in place instead of creating parallel artifacts.

- `product_owner`: creates or updates the specification as `Draft`.
- Human approval: explicitly authorizes the exact `Draft` revision for builder.
- `builder`: records the approved handoff as `Approved` on its task branch.
- `engineer`: advances `Approved` to `Planned` after planning.
- `builder`: advances `Planned` to `Coded`, then `Verified`, based on implementation and evidence.
- `dev_ops`: advances included `Verified` specifications to `Released` during a release.

## Custom Agents

| Agent | Responsibility |
| --- | --- |
| `product_owner` | Maintain one lifecycle specification for a work item. |
| `engineer` | Prepare implementation plans and applicable data models for builder. |
| `builder` | Coordinate committed implementation cycles and perform declared direct imports. |
| `tester` | Establish RED by changing tests only. |
| `coder` | Implement the minimum change for GREEN. |
| `cleaner` | Perform behavior-preserving REFACTOR. |
| `dev_ops` | Handle requested code documentation and releases. |
| `craftsman` | Maintain Codex agents, skills, prompts, and evaluations. |

## Skills

| Skill | Responsibility |
| --- | --- |
| `$project-bootstrap` | Explicitly create global project instructions, briefing, and changelog. |
| `$generating-specs` | Create or update one lifecycle specification for a work item. |
| `$planning-specs` | Create or update the single plan for an approved specification. |
| `$data-modeling` | Model changed persistent entities and relationships. |
| `$importing-nf-core` | Import an approved nf-core module or subworkflow with nf-core tools. |
| `$coding-spec` | Apply repository and language coding conventions. |
| `$linting` | Run repository lint checks and fix requested findings. |
| `$testing-unit` | Write and run isolated tests. |
| `$testing-e2e` | Test complete public-interface flows. |
| `$documenting-code` | Document source APIs and generate documentation artifacts. |
| `$start-task` | Prepare a local task branch. |
| `$commit-changes` | Create reviewed local commits. |
| `$push-changes` | Explicitly publish existing commits. |
| `$merging-default` | Explicitly merge a task branch locally. |
| `$releasing-version` | Explicitly prepare version and changelog changes. |

## Templates

| Template | Responsibility |
| --- | --- |
| [`agents.template.md`](templates/agents.template.md) | Base structure used by `craftsman` for Codex custom agents. |
