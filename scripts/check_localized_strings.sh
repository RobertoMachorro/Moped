#!/bin/zsh
set -euo pipefail

if ! command -v rg >/dev/null 2>&1; then
	echo "error: ripgrep (rg) is required for localization checks."
	exit 1
fi

swift_files=(Moped/*.swift)

patterns=(
	'\b(Button|CommandMenu)\("[A-Za-z]'
	'\bText\("[A-Za-z]'
	'\.messageText\s*=\s*"[A-Za-z]'
	'\.informativeText\s*=\s*"[A-Za-z]'
	'addButton\(withTitle:\s*"[A-Za-z]'
	'\.placeholderString\s*=\s*"[A-Za-z]'
	'\.title\s*=\s*"[A-Za-z]'
)

allowed_prefix='(about\.|alert\.|default_editor\.|menu\.|option\.|pref\.|window\.)'
violations=""

for pattern in "${patterns[@]}"; do
	while IFS= read -r line; do
		if [[ -z "$line" ]]; then
			continue
		fi

		if [[ "$line" == *'Text(document.model.docTypeName)'* ]]; then
			continue
		fi

		if [[ "$line" =~ '"'${allowed_prefix} ]]; then
			continue
		fi

		violations+="$line"$'\n'
	done < <(rg -n "$pattern" "${swift_files[@]}" || true)
done

if [[ -n "$violations" ]]; then
	echo "error: Found non-localized user-facing strings. Use localization keys in Localizable.xcstrings."
	echo "$violations" | sort -u
	exit 1
fi

echo "Localization key check passed."
