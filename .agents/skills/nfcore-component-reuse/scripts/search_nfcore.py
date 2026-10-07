#!/usr/bin/env python3

"""
Search for nf-core components.
"""

#!/usr/bin/env python3

import argparse
import json
from pathlib import Path

import yaml
from git import Repo

from nf_core.components.constants import NF_CORE_MODULES_REMOTE
from nf_core.modules.modules_utils import repo_full_name_from_remote
from nf_core.utils import NFCORE_DIR



def load_component(meta_file: Path, root: Path) -> dict:
    meta = yaml.safe_load(meta_file.read_text()) or {}

    return {
        "name": str(meta_file.parent.relative_to(root)),
        "description": meta.get("description"),
        "keywords": meta.get("keywords", []),
        "tools": meta.get("tools", []),
        "input": meta.get("input", []),
        "output": meta.get("output", []),
        "components": meta.get("components", []),
    }


def search(root: Path, terms: list[str]) -> list[dict]:
    results = []

    for meta_file in root.rglob("meta.yml"):
        component = load_component(meta_file, root)

        searchable = json.dumps(component, default=str).lower()

        if terms and not any(term in searchable for term in terms):
            continue

        results.append(component)

    return results


parser = argparse.ArgumentParser()
parser.add_argument("terms", nargs="*")
args = parser.parse_args()

terms = [term.lower() for term in args.terms]

repo_name = repo_full_name_from_remote(NF_CORE_MODULES_REMOTE)
repo_path = NFCORE_DIR / repo_name

if not (repo_path / ".git").exists():
    raise SystemExit(f"nf-core/modules repository not found: {repo_path}")

repo = Repo(repo_path)

result = {
    "repo": str(repo_path),
    "sha": repo.head.commit.hexsha,
    "modules": search(repo_path / "modules" / "nf-core", terms),
    "subworkflows": search(
        repo_path / "subworkflows" / "nf-core",
        terms,
    ),
}

print(json.dumps(result, indent=2, default=str))