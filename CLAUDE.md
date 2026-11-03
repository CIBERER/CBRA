@AGENTS.md

## Claude Code

- **Custom_Agents_Folder** for Claude Code: `/beegfs/home/cruizarenas/CBRA/.claude/agents`
  (generated from `.codex/agents`; after changing a Codex agent, run
  `python3 .claude/scripts/generate_agents.py`).
- Skills are shared: `.claude/skills` links to `.agents/skills`. A Codex `$skill` reference is the
  Claude Code skill `/skill`.
- Agent names use hyphens: `product_owner` is `product-owner` and `dev_ops` is `dev-ops`.
- Run user-facing roles as the main session so they can ask questions and delegate:
  `claude --agent <name>` for `analyst`, `architect`, `product-owner`, `craftsman`, `builder`, and
  `dev-ops`. `builder` delegates to the `engineer`, `tester`, `coder`, `cleaner`, `reviewer`, and
  `dev-ops` subagents.

### Model equivalence

Equivalent tier by capability and price (USD per 1M input/output tokens):

| Codex | Claude Code |
| --- | --- |
| `gpt-6-sol` | `claude-opus-5-5` ($4 / $20) |
| `gpt-5.6-terra` | `claude-sonnet-5-5` ($2 / $10) |
| `gpt-6-luna` | `claude-haiku-5-5` ($0.10 / $0.50) |

`model_reasoning_effort` maps 1:1 to the agent `effort` field.
