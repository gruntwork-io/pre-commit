#!/usr/bin/env bash

set -e

# Run helm package on the root path.
# A typical helm chart directory structure looks as follows:
#
#      root/
#      ├─ custom_chart1/
#      │  ├─ Chart.yaml
#      │  ├─ ...
#      ├─ index.yaml
#      ├─ README.md
#      ├─ charts/
#      │  ├─ custom_chart1-0.1.0.tgz
#      │  ├─ custom_chart2-1.2.3.tgz
#      ├─ custom_chart2/
#      │  ├─ Chart.yaml
#      │  ├─ ...
#
# The `Chart.yaml` file is metadata that helm uses to index the chart, and is added to the release info. It includes things
# like `name`, `version`, and `maintainers`.
# The `charts` directory are subcharts / dependencies that are deployed with the chart.
# The `templates` directory is what contains the go templates to render the Kubernetes resource yaml. Also includes
# helper template definitions (suffix `.tpl`).
#
# Any time files in `templates` or `charts` changes, we should run `helm lint`. `helm lint` can only be run on the root
# path of a chart, so this pre-commit hook will take the changed files and resolve it to the helm chart path. The helm
# chart path is determined by a heuristic: it is the directory containing the `Chart.yaml` file.
#
# Note that pre-commit will only feed this the files that changed in the commit, so we can't do the filtering at the
# hook setting level (e.g `files: Chart.yaml` will not work if no changes are made in the Chart.yaml file).

# OSX GUI apps do not pick up environment variables the same way as Terminal apps and there are no easy solutions,
# especially as Apple changes the GUI app behavior every release (see https://stackoverflow.com/q/135688/483528). As a
# workaround to allow GitHub Desktop to work, add this (hopefully harmless) setting here.
# Update the PATH environment variable to include the default installation path of helm.
export PATH=$PATH:/usr/local/bin

# Get the absolute path of the current working directory to know when to stop traversing up the directory tree.
readonly cwd_abspath="$(realpath "$PWD")"

# Function to check if an array contains a specific element.
# Usage: contains_element "value_to_find" "${array[@]}"
# Returns: 0 if found, 1 otherwise.
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

# Function to output debug information only when the PRECOMMIT_DEBUG environment variable is set.
# Outputs to stderr.
debug() {
  if [[ ! -z $PRECOMMIT_DEBUG ]]; then
    >&2 echo "$@"
  fi
}

# Function to recursively find the path of a Helm chart by traversing up from the file location until it finds a Chart.yaml.
# Usage: chart_path "path_of_changed_file"
# Returns: Path of the directory containing Chart.yaml or an empty string if not found.
chart_path() {
  local -r changed_file="$1"
  local -r changed_file_abspath="$(realpath "$changed_file")"
  local -r changed_file_dir="$(dirname "$changed_file_abspath")"

  debug "Checking directory $changed_file_abspath and $changed_file_dir for Chart.yaml"

  if [[ "$changed_file_abspath" == "$cwd_abspath" ]]; then
    debug "No chart path found"
    echo ""
    return 0
  fi

  if [[ "$(basename "$changed_file_abspath")" == "Chart.yaml" ]]; then
    debug "Chart path found: $changed_file_dir"
    echo "$changed_file_dir"
    return 0
  fi

  if [[ -f "$changed_file_abspath/Chart.yaml" ]]; then
    debug "Chart path found: $changed_file_abspath"
    echo "$changed_file_abspath"
    return 0
  fi

  if [[ -f "$changed_file_dir/Chart.yaml" ]]; then
    debug "Chart path found: $changed_file_dir"
    echo "$changed_file_dir"
    return 0
  fi

  chart_path "$changed_file_dir"
}

# Array to track which chart directories have already been packaged to avoid duplicate processing.
packaged_chart_paths=()

# Main loop to process each file passed to the script.
for file in "$@"; do
  debug "Checking $file"
  file_chart_path=$(chart_path "$file")
  debug "Resolved $file to chart path $file_chart_path"

  if [[ ! -z "$file_chart_path" ]] && ! contains_element "$file_chart_path" "${packaged_chart_paths[@]}"; then
    # Package the chart and add its path to the list of packaged charts.
    helm package "$file_chart_path" -d $cwd_abspath/charts
    packaged_chart_paths+=( "$file_chart_path" )
    debug "Packaged $file_chart_path"
  fi
done

# After all charts have been packaged, update the index for the repository.
# This assumes that the script is run from the repository root.
helm repo index $cwd_abspath
debug "Repository index updated."
