#!/bin/bash

set -e

# OSX GUI apps do not pick up environment variables the same way as Terminal apps and there are no easy solutions,
# especially as Apple changes the GUI app behavior every release (see https://stackoverflow.com/q/135688/483528). As a
# workaround to allow GitHub Desktop to work, add this (hopefully harmless) setting here.
export PATH=$PATH:/usr/local/bin

readonly STYLE="{BASED_ON_STYLE: google, ALIGN_CLOSING_BRACKET_WITH_VISUAL_INDENT: true, COLUMN_LIMIT: 120, BLANK_LINE_BEFORE_NESTED_CLASS_OR_DEF: true, COALESCE_BRACKETS: false, DEDENT_CLOSING_BRACKETS: true, SPLIT_BEFORE_DOT: true, SPLIT_COMPLEX_COMPREHENSION: true}"

for file in "$@"; do
  if [[ "$file" =~ \.py$ ]]; then
    yapf -ri --style="$STYLE" "$file"
  fi
done
