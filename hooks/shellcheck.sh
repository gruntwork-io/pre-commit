#!/usr/bin/env bash

set -e

# OSX GUI apps do not pick up environment variables the same way as Terminal apps and there are no easy solutions,
# especially as Apple changes the GUI app behavior every release (see https://stackoverflow.com/q/135688/483528). As a
# workaround to allow GitHub Desktop to work, add this (hopefully harmless) setting here.
export PATH=$PATH:/usr/local/bin

exit_status=0
ENABLE_LIST=""

# Arguments
parse_arguments() {
  while [ $# -gt 0 ]; do
    # Get param and value using parameter expansion, splitting on = or " "
    param="${1%[ =]*}"
    value="${1#*[ =]}"
    if [ "$param" = "$value" ]; then value="$2"; fi
    shift
    case "$param" in
    --enable)
      ENABLE_LIST="$ENABLE_LIST $value"
      ;;
    -*)
      echo "Error: Unknown option: $param" >&2
      exit 1
      ;;
    *)
      PARAMS="$PARAMS $param"
      ;;
    esac
  done
  ENABLE_LIST="${ENABLE_LIST## }" # remove preceeding space
}

parse_arguments "$@"

for file in $PARAMS; do
  if (head -1 "$file" | grep '^#!.*sh'>/dev/null); then
    SHELLCHECK_ARGS=""
    if [ "$ENABLE_LIST" != "" ]; then
      SHELLCHECK_ARGS+="--enable=\"$ENABLE_LIST\" "
    fi
    if ! eval "shellcheck $SHELLCHECK_ARGS\"$file\""; then
      exit_status=1
    fi
  elif [[ "$file" =~ \.sh$|bash$ ]]; then
    echo "$file: missing shebang"
    exit_status=1
  fi
done

exit $exit_status
