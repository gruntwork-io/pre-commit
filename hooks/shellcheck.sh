#!/usr/bin/env bash

set -e

# OSX GUI apps do not pick up environment variables the same way as Terminal apps and there are no easy solutions,
# especially as Apple changes the GUI app behavior every release (see https://stackoverflow.com/q/135688/483528). As a
# workaround to allow GitHub Desktop to work, add this (hopefully harmless) setting here.
export PATH=$PATH:/usr/local/bin

exit_status=0
enable_list=""

parse_arguments() {
	while (($# > 0)); do
		# Grab param and value splitting on " " or "=" with parameter expansion
		local PARAMETER="${1%[ =]*}"
		local VALUE="${1#*[ =]}"
		if [[ "$PARAMETER" == "$VALUE" ]]; then VALUE="$2"; fi
		shift
		case "$PARAMETER" in
		--enable)
			enable_list="$enable_list $VALUE"
			;;
		-*)
			echo "Error: Unknown option: $PARAMETER" >&2
			exit 1
			;;
		*)
			files="$files $PARAMETER"
			;;
		esac
	done
	enable_list="${enable_list## }" # remove preceeding space
}

parse_arguments "$@"

for FILE in $files; do
	SHEBANG_REGEX='^#!\(/\|/.*/\|/.* \)\(\(ba\|da\|k\|a\)*sh\|bats\)$'
	if (head -1 "$FILE" | grep "$SHEBANG_REGEX" >/dev/null); then
		if ! shellcheck ${enable_list:+ --enable="$enable_list"} "$FILE"; then
			exit_status=1
		fi
	elif [[ "$FILE" =~ .+\.(sh|bash|dash|ksh|ash|bats)$ ]]; then
		echo "$FILE: missing shebang"
		exit_status=1
	fi
done

exit $exit_status
