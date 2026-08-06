#!/bin/zsh
set -euo pipefail

if ! command -v rg >/dev/null 2>&1; then
	echo "error: ripgrep (rg) is required for localization checks."
	exit 1
fi

# Recursive so the check keeps covering sources if they ever move into subfolders.
swift_files=(Moped/**/*.swift)

# Each pattern captures the whole string literal, not just its first character, so the
# allowlist below can be matched against the literal itself rather than the whole line.
patterns=(
	'\b(Button|CommandMenu|Toggle|Label|Picker)\("[A-Za-z][^"]*"'
	'\bText\("[A-Za-z][^"]*"'
	'\.navigationTitle\("[A-Za-z][^"]*"'
	'\.messageText\s*=\s*"[A-Za-z][^"]*"'
	'\.informativeText\s*=\s*"[A-Za-z][^"]*"'
	'addButton\(withTitle:\s*"[A-Za-z][^"]*"'
	'\.placeholderString\s*=\s*"[A-Za-z][^"]*"'
	'\.title\s*=\s*"[A-Za-z][^"]*"'
)

allowed_prefix='(about\.|alert\.|default_editor\.|error\.|menu\.|option\.|pref\.|window\.)'
violations=""

for pattern in "${patterns[@]}"; do
	while IFS= read -r line; do
		if [[ -z "$line" ]]; then
			continue
		fi

		# `--vimgrep -o` yields file:line:col:<matched call>, so split the location off and
		# test the allowlist against the matched literal alone. Matching the whole source
		# line instead would let `Button("menu.ok") { alert("Oops") }` pass on the key.
		if [[ "$line" =~ '^([^:]+:[0-9]+:[0-9]+):(.*)$' ]]; then
			literal="${match[2]}"
		else
			literal="$line"
		fi

		if [[ "$literal" == *'document.model.docTypeName'* ]]; then
			continue
		fi

		if [[ "$literal" =~ '"'${allowed_prefix} ]]; then
			continue
		fi

		violations+="$line"$'\n'
	done < <(rg --vimgrep -o "$pattern" "${swift_files[@]}" || true)
done

if [[ -n "$violations" ]]; then
	echo "error: Found non-localized user-facing strings. Use localization keys in Localizable.xcstrings."
	echo "$violations" | sort -u
	exit 1
fi

echo "Localization key check passed."
