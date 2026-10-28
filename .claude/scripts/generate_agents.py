# Regenerate .claude/agents/*.md from .codex/agents/*.toml.
# Usage: python3 .claude/scripts/generate_agents.py [repository-root]
import glob, os, re, sys

root = sys.argv[1] if len(sys.argv) > 1 else os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
MODELS = {"gpt-6-sol": "claude-opus-5-5", "gpt-5.6-terra": "claude-sonnet-5-5", "gpt-6-luna": "claude-haiku-5-5"}
BASE = "Read, Grep, Glob, Skill"
TOOLS = {
    "analyst": "Write, Edit, WebSearch, WebFetch, AskUserQuestion",
    "architect": "Bash, Write, Edit, WebSearch, WebFetch, AskUserQuestion",
    "product-owner": "Write, Edit, AskUserQuestion",
    "craftsman": "Bash, Write, Edit, WebSearch, WebFetch, AskUserQuestion",
    "builder": "Agent(engineer, tester, coder, cleaner, reviewer, dev-ops), Bash, Edit, TodoWrite, AskUserQuestion",
    "engineer": "Bash, Write, Edit, WebFetch",
    "tester": "Bash, Write, Edit",
    "coder": "Bash, Write, Edit",
    "cleaner": "Bash, Edit",
    "reviewer": "Bash",
    "dev-ops": "Bash, Write, Edit",
}

out_dir = os.path.join(root, ".claude", "agents")
os.makedirs(out_dir, exist_ok=True)
for path in sorted(glob.glob(os.path.join(root, ".codex", "agents", "*.toml"))):
    text = open(path).read()
    field = lambda k: re.search(r'^%s = "(.*)"$' % k, text, re.M).group(1)
    body = re.search(r'developer_instructions = """\n(.*?)"""', text, re.S).group(1)
    name = field("name").replace("_", "-")
    front = [
        "---",
        "name: %s" % name,
        "description: %s" % field("description"),
        "model: %s" % MODELS[field("model")],
        "effort: %s" % field("model_reasoning_effort"),
        "tools: %s, %s" % (BASE, TOOLS[name]),
        "---",
        "",
    ]
    with open(os.path.join(out_dir, name + ".md"), "w") as fh:
        fh.write("\n".join(front) + body)
    print(name, MODELS[field("model")], field("model_reasoning_effort"))
