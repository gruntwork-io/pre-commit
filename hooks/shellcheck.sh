#!/usr/bin/env bash

set -e

# OSX GUI apps do not pick up environment variables the same way as Terminal apps and there are no easy solutions,
# especially as Apple changes the GUI app behavior every release (see https://stackoverflow.com/q/135688/483528). As a
# workaround to allow GitHub Desktop to work, add this (hopefully harmless) setting here.
export PATH=$PATH:/usr/local/bin

readonly SHEBANG_REGEX='^#!\(/\|/.*/\|/.* \)\(\(ba\|da\|k\|a\)*sh\|bats\)$'

function shellcheck_files {
  local -r enable_list="$1"
  local -r files="$2"

  local exit_status=0

  for file in $files; do
    if (head -1 "$file" | grep "$SHEBANG_REGEX" >/dev/null); then
      if ! shellcheck ${enable_list:+ --enable="$enable_list"} "$file"; then
        exit_status=1
      fi
    elif [[ "$file" =~ .+\.(sh|bash|dash|ksh|ash|bats)$ ]]; then
      echo "$file: missing shebang"
      exit_status=1
    fi
  done

  exit $exit_status
}

function run {
  local enable_list=""
  local files=""

  local parameter=""
  local value=""

  while [[ $# -gt 0 ]]; do
    # Grab param and value splitting on " " or "=" with parameter expansion
    parameter="${1%[ =]*}"
    value="${1#*[ =]}"
    if [[ "$parameter" == "$value" ]]; then
      value="$2"
    fi
    shift

    case "$parameter" in
    --enable)
      enable_list="$enable_list $value"
      shift
      ;;
    -*)
      echo "Error: Unknown option: $parameter" >&2
      exit 1
      ;;
    *)
      files="$files $parameter"
      ;;
    esac
  done
  # remove preceeding space from enable_list, which is included in the first arg
  enable_list="${enable_list## }"

  shellcheck_files "$enable_list" "$files"
}

run "$@"
