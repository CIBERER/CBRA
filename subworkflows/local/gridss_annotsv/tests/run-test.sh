#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
cd "$repo_root"
export NXF_SYNTAX_PARSER=v1
nf-test test subworkflows/local/gridss_annotsv/tests/main.nf.test --ci
