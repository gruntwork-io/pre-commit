#!/bin/bash

set -e

# OSX GUI apps do not pick up environment variables the same way as Terminal apps and there are no easy solutions,
# especially as Apple changes the GUI app behavior every release (see https://stackoverflow.com/q/135688/483528). As a
# workaround to allow GitHub Desktop to work, add this (hopefully harmless) setting here.
export PATH=$PATH:/usr/local/bin

if ! command -v asciidoc-link-check; then
  >&2 echo "asciidoc-link-check is not available on this system."
  >&2 echo "Please install it by running 'npm install -g asciidoc-link-check'"
  exit 1
fi

for file in "$@"; do
  asciidoc-link-check "$file"
done
