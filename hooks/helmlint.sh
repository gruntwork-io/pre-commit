#!/bin/bash

# OSX GUI apps do not pick up environment variables the same way as Terminal apps and there are no easy solutions,
# especially as Apple changes the GUI app behavior every release (see https://stackoverflow.com/q/135688/483528). As a
# workaround to allow GitHub Desktop to work, add this (hopefully harmless) setting here.
export PATH=$PATH:/usr/local/bin

readonly cwd_abspath="$(realpath "$PWD")"

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

log() {
  if [[ $PRECOMMIT_DEBUG ]]; then
    echo "$@"
  fi
}

# Recursively walk up the tree until the current working directory and check if the changed file is part of a helm
# chart. Helm charts have a Chart.yaml file.
chart_path_return=""
chart_path() {
  # Return return value
  chart_path_return=""

  local -r changed_file="$(realpath "$1")"
  local -r changed_file_dir="$(dirname "$changed_file")"

  log "Checking directory $changed_file and $changed_file_dir for Chart.yaml"

  if [[ "$changed_file" == "$cwd_abspath" ]]; then
    log "No chart path found"
    return 0
  fi
  if [[ "$(basename "$changed_file")" == "Chart.yaml" ]]; then
    chart_path_return="$changed_file_dir"
    log "Chart path found: $chart_path_return"
    return 0
  fi
  if [[ -f "$changed_file/Chart.yaml" ]]; then
    chart_path_return="$changed_file"
    log "Chart path found: $chart_path_return"
    return 0
  fi
  if [[ -f "$changed_file_dir/Chart.yaml" ]]; then
    chart_path_return="$changed_file_dir"
    log "Chart path found: $chart_path_return"
    return 0
  fi
  chart_path "$changed_file_dir"
}

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
  log "Checking $file"
  check_changed_file "$file"
done
