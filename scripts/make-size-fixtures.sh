#!/bin/bash
#
# make-size-fixtures.sh — generate the size-tier fixtures that are too large
# to commit, sized against the limits in MopedDocument.swift.
#
# Creates in TestFiles/Sizes/ (both gitignored):
#   8MB.txt      — opens: over the 256 KB large-file threshold, under the 16 MB limit
#   Over16MB.txt — refused: just past the 16 MB maxFileLength
#
# Used by manual-checklist.md for the large-file open/refusal checks.

set -euo pipefail

DIR="$(cd "$(dirname "$0")/.." && pwd)/TestFiles/Sizes"
LINE="The quick brown fox jumps over the lazy dog. Moped size-tier test line."

make_file() {
	local target="$1"
	local bytes="$2"
	# `yes` dies of SIGPIPE when `head` closes the pipe — expected here, so
	# pipefail is suspended for this one pipeline.
	set +o pipefail
	yes "$LINE" | head -c "$bytes" > "$target"
	set -o pipefail
}

make_file "$DIR/8MB.txt" $((8 * 1024 * 1024))
make_file "$DIR/Over16MB.txt" $((16 * 1024 * 1024 + 1024))

ls -l "$DIR/8MB.txt" "$DIR/Over16MB.txt"
