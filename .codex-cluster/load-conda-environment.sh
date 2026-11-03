#!/usr/bin/env bash

# Source this script from within the selected Slurm allocation before running
# development commands. It loads Miniconda and activates the nf-dev environment.
#
# Usage:
#   source .codex-cluster/load-conda-environment.sh

readonly CONDA_MODULE='Miniconda3/23.10.0-1'
readonly CONDA_ENVIRONMENT_PATH='/home/cruizarenas/.conda/envs/nf-dev'

if ! type module >/dev/null 2>&1; then
    echo "load-conda-environment: environment modules are unavailable in this shell" >&2
    return 1 2>/dev/null || exit 1
fi

module load "$CONDA_MODULE"

if ! command -v conda >/dev/null 2>&1; then
    echo "load-conda-environment: Conda is unavailable after loading ${CONDA_MODULE}" >&2
    return 1 2>/dev/null || exit 1
fi

conda_base="$(conda info --base)"
conda_hook="${conda_base}/etc/profile.d/conda.sh"
if [[ ! -r $conda_hook ]]; then
    echo "load-conda-environment: Conda activation hook is unavailable: ${conda_hook}" >&2
    return 1 2>/dev/null || exit 1
fi

source "$conda_hook"
conda activate "$CONDA_ENVIRONMENT_PATH"
