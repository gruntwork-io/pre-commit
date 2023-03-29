#!/usr/bin/env bash

set -e

# OSX GUI apps do not pick up environment variables the same way as Terminal apps and there are no easy solutions,
# especially as Apple changes the GUI app behavior every release (see https://stackoverflow.com/q/135688/483528). As a
# workaround to allow GitHub Desktop to work, add this (hopefully harmless) setting here.
export PATH=$PATH:/usr/local/bin

# Install any plugins defined in .tflint.hcl
tflint --init


declare -a FILES
declare -a ARGS
while [[ $# -gt 0 ]]
do
  case "$1" in
    -*) ARGS+=("$1")
      ;;
    *) FILES+=("$1")
      ;;
  esac
  shift
done

for file in "${FILES[@]}"
do
  tflint "${ARGS[@]}" "$file"
done
