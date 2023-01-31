#!/usr/bin/env bash

set -e

# OSX GUI apps do not pick up environment variables the same way as Terminal apps and there are no easy solutions,
# especially as Apple changes the GUI app behavior every release (see https://stackoverflow.com/q/135688/483528). As a
# workaround to allow GitHub Desktop to work, add this (hopefully harmless) setting here.
export PATH=$PATH:/usr/local/bin

if ! command -v markdown-link-check; then
  >&2 echo "markdown-link-check is not available on this system."
  >&2 echo "Please install it by running 'npm install -g markdown-link-check'"
  exit 1
fi

# This is the recommended way to set the project root for properly resolving absolute paths. See
# https://github.com/tcort/markdown-link-check/issues/16 for more info.
# markdown-link-check 3.10 introduced checking anchors, which does not work witihn the same file. See
# https://github.com/tcort/markdown-link-check/issues/195
TMP_CONFIG="$(mktemp)"
cat > "$TMP_CONFIG" <<EOF
{
  "replacementPatterns": [
    {
      "pattern": "^/",
      "replacement": "file://$(pwd)/"
    }
  ],
  "ignorePatterns": [
    {
      "pattern": "^#"
    }
  ]  
}
EOF

for file in "$@"; do
  markdown-link-check -c "$TMP_CONFIG" "$file"
done
