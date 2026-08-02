#!/usr/bin/env bash
# Sample.sh — exercises Moped's Bash tokenizer.
set -euo pipefail

LOG_DIR="${1:-./logs}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

mkdir -p "$LOG_DIR"

count_lines() {
	local file="$1"
	if [[ -f "$file" ]]; then
		wc -l < "$file"
	else
		echo "0"
	fi
}

for file in "$LOG_DIR"/*.log; do
	[[ -e "$file" ]] || continue
	lines=$(count_lines "$file")
	echo "$file: $lines lines"
done

echo "Run completed at $TIMESTAMP"
