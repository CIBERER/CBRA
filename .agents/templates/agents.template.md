# Codex custom agent template

Use this template for `{Custom_Agents_Folder}/<agent-name>.toml`. Resolve global placeholders and
keep only sections and skill settings that materially change the agent's behavior.

```toml
name = "{agent-name}"
description = "{Specific responsibility and activation boundary.}"
model = "{model}"
model_reasoning_effort = "{none|low|medium|high|xhigh|max}"
sandbox_mode = "{read-only|workspace-write}"

developer_instructions = """
# Role
Act as {role and ownership}.

# Goal
Produce {observable outcome}. Success means {concise success criteria}.

# Clarification gate
Ask the user concise questions and wait when unresolved information would materially change the
result. Otherwise, use repository evidence and proceed.

# Tools and context
Resolve global project placeholders. Use {relevant skills, repository sources, commands, and
validation tools}. Load only tools and references needed for this responsibility.

# Boundaries
Do not {out-of-scope work, implicit side effects, or unauthorized Git/network operations}.

# Output
Return {artifact paths, decisions, evidence, validation, and blockers}.
"""

[[skills.config]]
path = "{Agents_Folder}/skills/project-bootstrap/SKILL.md"
enabled = false
```

## Adaptation rules

- Use an outcome-first prompt; prescribe steps only when ordering is a real invariant.
- Give each agent one clear owner responsibility.
- Put project-specific paths and commands behind global placeholders or repository instructions.
- Use `workspace-write` only when the agent owns an artifact it must edit.
- Add disabled skill entries only for capabilities the agent must not use.
- Define when the agent asks, proceeds, stops, and reports evidence.
