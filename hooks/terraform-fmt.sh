#!/usr/bin/env bash

set -e

# OSX GUI apps do not pick up environment variables the same way as Terminal apps and there are no easy solutions,
# especially as Apple changes the GUI app behavior every release (see https://stackoverflow.com/q/135688/483528). As a
# workaround to allow GitHub Desktop to work, add this (hopefully harmless) setting here.
export PATH=$PATH:/usr/local/bin

write_changes=true
FILES=()

parse_arguments() {
	while (($# > 0)); do
		# Grab param and value splitting on " " or "=" with parameter expansion
		local PARAMETER="${1%[ =]*}"
		local VALUE="${1#*[ =]}"
		if [[ "$PARAMETER" == "$VALUE" ]]; then VALUE="$2"; fi
		shift
		case "$PARAMETER" in
		--no-autofix)
			write_changes=false
			;;
		-*)
			echo "Error: Unknown option: $PARAMETER" >&2
			exit 1
			;;
		*)
			FILES+=("$PARAMETER")
			;;
		esac
	done
}

parse_arguments "$@"

# Store and return last failure from fmt so this can validate every directory passed before exiting
FMT_ERROR=0

for file in "$FILES"; do
  file=$(dirname "$file")
  if [ "$write_changes" = true ]; then
    terraform fmt "$file" || FMT_ERROR=$?
  else
    terraform fmt -diff -check "$file" || FMT_ERROR=$?
  fi
done

exit ${FMT_ERROR}
