# Agent Instructions

- **Root_Folder**: `/beegfs/home/cruizarenas/CBRA`
- **Agents_Folder**: `/beegfs/home/cruizarenas/CBRA/.agents`
- **Custom_Agents_Folder**: `/beegfs/home/cruizarenas/CBRA/.codex/agents`
- **Agents_file**: `/beegfs/home/cruizarenas/CBRA/AGENTS.md`
- **Project_Folder**: `/beegfs/home/cruizarenas/CBRA/agents_data`
- **Briefing_file**: `/beegfs/home/cruizarenas/CBRA/agents_data/briefing.md`
- **Specs_Folder**: `/beegfs/home/cruizarenas/CBRA/agents_data/specs`
- **Plans_Folder**: `/beegfs/home/cruizarenas/CBRA/agents_data/plans`

## Project

CBRA is an nf-core-style Nextflow DSL2 pipeline for rare-disease variant analysis.
Use the Nextflow, Groovy, nf-core, and nf-test profiles in `.agents/skills` when they apply.

## Development execution

At the start of work, read [the Conda environment instructions](.codex-cluster/load-conda-environment.sh).
Source that script only from within the selected Slurm allocation.

Run local read-only repository inspection directly. This includes `git status`, `git diff`,
`git log`, `rg`, `sed`, `ls`, `find`, and `stat`; it does not require Slurm.

Before executing code, tests, linters, builds, Nextflow, installations, or other development
tools, run `hostname -s`. If the host is `login01`, stop and ask confirmation. Otherwise, run the command directly.

If the wrapper fails with Slurm stream-socket permission errors in an isolated environment, retry
the same wrapper command with escalated access to the Slurm controller. Stop and tell the user only
if that retry fails. File inspection without running tools is always allowed without the wrapper.

## Agent artifacts

Store the product briefing, lifecycle specifications, and implementation plans only in
`agents_data/`.

## Conventions

- Code and documentation are in English; respond in the user's language.
- Use hyphenated slugs for non-code filenames and identifiers.
