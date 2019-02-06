#!/bin/bash

# We don't set `set -e` in this script because some of the functions will return a non-zero value (e.g contains_element)

# OSX GUI apps do not pick up environment variables the same way as Terminal apps and there are no easy solutions,
# especially as Apple changes the GUI app behavior every release (see https://stackoverflow.com/q/135688/483528). As a
# workaround to allow GitHub Desktop to work, add this (hopefully harmless) setting here.
export PATH=$PATH:/usr/local/bin

# Take the current working directory to know when to stop walking up the tree
readonly cwd_abspath="$(realpath "$PWD")"

# An array to keep track of which charts we already linted
seen_chart_paths=()

# https://stackoverflow.com/a/8574392
# Usage: contains_element "val" "${array[@]}"
# Returns: 0 if there is a match, 1 otherwise
contains_element() {
  local -r match="$1"
  shift

  for e in "$@"; do
    if [[ "$e" == "$match" ]]; then
      return 0
    fi
  done
  return 1
}

# Only log debug statements if PRECOMMIT_DEBUG environment variable is set.
debug() {
  if [[ $PRECOMMIT_DEBUG ]]; then
    echo "$@"
  fi
}

# Recursively walk up the tree until the current working directory and check if the changed file is part of a helm
# chart. Helm charts have a Chart.yaml file.
# Return value is stored in `chart_path_return`
chart_path_return=""
chart_path() {
  # Return return value
  chart_path_return=""

  # We check both the current dir as well as the parent dir, in case the current dir is a file
  local -r changed_file="$(realpath "$1")"
  local -r changed_file_dir="$(dirname "$changed_file")"

  debug "Checking directory $changed_file and $changed_file_dir for Chart.yaml"

  # Base case: we have walked to the top of dir tree
  if [[ "$changed_file" == "$cwd_abspath" ]]; then
    debug "No chart path found"
    return 0
  fi

  # The changed file is itself the helm chart indicator, Chart.yaml
  if [[ "$(basename "$changed_file")" == "Chart.yaml" ]]; then
    chart_path_return="$changed_file_dir"
    debug "Chart path found: $chart_path_return"
    return 0
  fi

  # The changed_file is the directory containing the helm chart package file
  if [[ -f "$changed_file/Chart.yaml" ]]; then
    chart_path_return="$changed_file"
    debug "Chart path found: $chart_path_return"
    return 0
  fi

  # The directory of changed_file is the directory containing the helm chart package file
  if [[ -f "$changed_file_dir/Chart.yaml" ]]; then
    chart_path_return="$changed_file_dir"
    debug "Chart path found: $chart_path_return"
    return 0
  fi

  # None of the above, so recurse and do again in the parent dir
  chart_path "$changed_file_dir"
}

# Check if the provided changed file is a chart path, and run helm lint if it is
check_changed_file() {
  chart_path "$1"
  contains_element "$chart_path_return" "${seen_chart_paths[@]}"
  if [[ $? -eq 0 ]]; then
    return
  fi

  if [[ "$chart_path_return" != "" ]]; then
    helm lint "$chart_path_return"
    if [[ $? -ne 0 ]]; then
      exit 1
    fi
  fi
  seen_chart_paths+=( "$chart_path_return" )
}

for file in "$@"; do
  debug "Checking $file"
  check_changed_file "$file"
done
