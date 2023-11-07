#!/usr/bin/env bash

set -e

# OSX GUI apps do not pick up environment variables the same way as Terminal apps and there are no easy solutions,
# especially as Apple changes the GUI app behavior every release (see https://stackoverflow.com/q/135688/483528). As a
# workaround to allow GitHub Desktop to work, add this (hopefully harmless) setting here.
export PATH=$PATH:/usr/local/bin

# allow customization of the repo root keyword
PRECOMMIT_TFLINT_REPO_ROOT_KEYWORD=${PRECOMMIT_TFLINT_REPO_ROOT_KEYWORD:-__GIT_ROOT__}

process_arg() {
  local arg
  local repo_root

  arg="${1}"
  repo_root="$(pwd)"

  case "${arg}" in
    "--config"*)
      echo "${arg//$PRECOMMIT_TFLINT_REPO_ROOT_KEYWORD/$repo_root}"
      ;;
    *)
      echo "${arg}"
  esac
}

declare -a FILES
declare -a ARGS
while [[ $# -gt 0 ]]
do
  case "$1" in
    -*) ARGS+=("$(process_arg "$1")")
      ;;
    *) FILES+=("$1")
      ;;
  esac
  shift
done

# Install any plugins defined in .tflint.hcl
tflint "${ARGS[@]}" --init

for file in "${FILES[@]}"
do
  tflint "${ARGS[@]}" --chdir "$(dirname "$file")" --filter "$(basename "$file")"
done
