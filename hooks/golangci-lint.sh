#!/usr/bin/env bash

set -e

# OSX GUI apps do not pick up environment variables the same way as Terminal apps and there are no easy solutions,
# especially as Apple changes the GUI app behavior every release (see https://stackoverflow.com/q/135688/483528). As a
# workaround to allow GitHub Desktop to work, add this (hopefully harmless) setting here.
original_path=$PATH
export PATH=$PATH:/usr/local/bin

# Store and return last failure from fmt so this can validate every directory passed before exiting
FMT_ERROR=0

for file in "$@"; do
  golangci-lint run --new-from-rev HEAD "$file" || FMT_ERROR=$?
done

# reset path to the original value
export PATH=$original_path

exit ${FMT_ERROR}
