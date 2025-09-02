#!/usr/bin/env bash

set -e

# OSX GUI apps do not pick up environment variables the same way as Terminal apps and there are no easy solutions,
# especially as Apple changes the GUI app behavior every release (see https://stackoverflow.com/q/135688/483528). As a
# workaround to allow GitHub Desktop to work, add this (hopefully harmless) setting here.
export PATH=$PATH:/usr/local/bin

check_terragrunt_version() {
  local minimum_supported_version="0.77.22"
  local current_version
  local version_output

  if ! command -v terragrunt >/dev/null 2>&1; then
    echo "Warning: terragrunt command not found. Proceeding anyway..." >&2

    return 0
  fi

  version_output=$(terragrunt --version 2>/dev/null)

  if [[ "$version_output" == *"latest"* ]]; then
    return 0
  fi

  if ! current_version=$(echo "$version_output" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1); then
    echo "Warning: Could not determine terragrunt version. Proceeding anyway..." >&2

    return 0
  fi

  if [ "$(printf '%s\n' "$minimum_supported_version" "$current_version" | sort -V | head -1)" = "$minimum_supported_version" ]; then
    return 0
  fi

  echo "Error: Terragrunt version $current_version is less than the minimum supported version $minimum_supported_version" >&2
  echo "Please upgrade Terragrunt to version $minimum_supported_version or later" >&2

  exit 1
}

format_files() {
  for file in "$@"; do
    pushd "$(dirname "$file")" >/dev/null
    terragrunt hcl fmt --file "$(basename "$file")"
    popd >/dev/null
  done
}

main() {
  check_terragrunt_version
  format_files "$@"
}

main "$@"
