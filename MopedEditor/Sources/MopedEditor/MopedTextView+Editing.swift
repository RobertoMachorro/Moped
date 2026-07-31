//
//  MopedTextView+Editing.swift
//
//  MopedEditor - The homegrown text editor core and syntax highlighter used by Moped.
//  Copyright © 2019-2026 Roberto Machorro. All rights reserved.
//
//	This program is free software: you can redistribute it and/or modify
//	it under the terms of the GNU General Public License as published by
//	the Free Software Foundation, either version 3 of the License, or
//	(at your option) any later version.
//
//	This program is distributed in the hope that it will be useful,
//	but WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//	GNU General Public License for more details.
//
//	You should have received a copy of the GNU General Public License
//	along with this program.  If not, see <https://www.gnu.org/licenses/>.
//

import AppKit
import UniformTypeIdentifiers

extension MopedTextView {
	enum IndentStyle: Equatable {
		case hardTab
		case softSpaces(Int)

		var indentUnit: String {
			switch self {
			case .hardTab:
				return "\t"
			case .softSpaces(let width):
				return String(repeating: " ", count: max(width, 1))
			}
		}
	}

	private static let maxLinesToAnalyzeForIndent = 1000

	// MARK: Plain-text input

	/// Always paste as plain text so attributes from the source app (Xcode colors, RTF
	/// fonts, etc.) don't override the editor's theme and font.
	public override func paste(_ sender: Any?) {
		pasteAsPlainText(sender)
	}

	/// Drag-in counterpart to `paste`. Internal drags (moving selected text within the
	/// same editor) keep the default path; external drags land as plain text.
	public override func performDragOperation(_ sender: any NSDraggingInfo) -> Bool {
		if sender.draggingSource as AnyObject? === self {
			return super.performDragOperation(sender)
		}
		let pasteboard = sender.draggingPasteboard
		if pasteboard.canReadItem(withDataConformingToTypes: [UTType.plainText.identifier]) {
			return readSelection(from: pasteboard, type: .string)
		}
		return false
	}

	public override func insertText(_ insertString: Any, replacementRange: NSRange) {
		super.insertText(insertString, replacementRange: replacementRange)
		cachedIndentStyle = nil
	}

	// MARK: Auto-indent and tabs

	public override func insertNewline(_ sender: Any?) {
		guard !hasMarkedText() else {
			super.insertNewline(sender)
			return
		}
		let nsText = string as NSString
		let selection = selectedRange()
		let caretLocation = min(selection.location, nsText.length)
		let searchRange = NSRange(location: 0, length: caretLocation)
		let previousNewline = nsText.range(of: "\n", options: .backwards, range: searchRange)
		let lineStart = previousNewline.location == NSNotFound ? 0 : previousNewline.location + 1
		var indentEnd = lineStart
		while indentEnd < nsText.length {
			let character = nsText.character(at: indentEnd)
			if character != 9 && character != 32 {
				break
			}
			indentEnd += 1
		}
		let indent = nsText.substring(with: NSRange(location: lineStart, length: indentEnd - lineStart))
		insertText("\n" + indent, replacementRange: selection)
	}

	public override func insertTab(_ sender: Any?) {
		guard !hasMarkedText() else {
			super.insertTab(sender)
			return
		}
		let selection = selectedRange()
		if selection.length > 0 {
			_ = adjustIndentation(true)
			return
		}

		switch detectIndentStyle(in: string) {
		case .hardTab:
			super.insertTab(sender)
		case .softSpaces(let width):
			let source = string as NSString
			let searchRange = NSRange(location: 0, length: selection.location)
			let previousNewline = source.range(of: "\n", options: .backwards, range: searchRange)
			let lineStart = previousNewline.location == NSNotFound ? 0 : previousNewline.location + 1
			let column = selection.location - lineStart
			let spacesToInsert = width - (column % width)
			insertText(String(repeating: " ", count: spacesToInsert), replacementRange: selection)
		}
	}

	public override func insertBacktab(_ sender: Any?) {
		guard !hasMarkedText(), adjustIndentation(false) else {
			super.insertBacktab(sender)
			return
		}
	}

	public override func performKeyEquivalent(with event: NSEvent) -> Bool {
		let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
		guard !hasMarkedText(),
			  modifiers == .command,
			  let key = event.charactersIgnoringModifiers
		else {
			return super.performKeyEquivalent(with: event)
		}

		switch key {
		case "[":
			return adjustIndentation(false)
		case "]":
			return adjustIndentation(true)
		default:
			return super.performKeyEquivalent(with: event)
		}
	}

	// MARK: Indent / outdent

	@discardableResult
	func adjustIndentation(_ shouldIndent: Bool) -> Bool {
		guard isEditable else {
			return false
		}

		let source = string as NSString
		let selection = selectedRange()
		let lineRange = normalizedLineRange(for: selection, in: source)
		let style = detectIndentStyle(in: string)
		let originalBlock = source.substring(with: lineRange)

		let transformedBlock = shouldIndent
			? applyIndent(to: originalBlock, indentUnit: style.indentUnit)
			: applyOutdent(to: originalBlock, style: style)

		return replaceBlock(
			in: lineRange, with: transformedBlock, original: originalBlock, selection: selection
		)
	}

	/// Applies a whole-line-block replacement as a single undoable edit and restores
	/// a sensible selection. Returns true when the gesture was handled.
	func replaceBlock(
		in lineRange: NSRange, with transformedBlock: String, original: String, selection: NSRange
	) -> Bool {
		guard transformedBlock != original else {
			return true
		}
		guard let textStorage,
			  shouldChangeText(in: lineRange, replacementString: transformedBlock)
		else {
			return true
		}

		textStorage.replaceCharacters(in: lineRange, with: transformedBlock)
		textStorage.setAttributes(
			[.font: editorFont, .foregroundColor: theme.foreground],
			range: NSRange(location: lineRange.location, length: (transformedBlock as NSString).length)
		)
		didChangeText()
		cachedIndentStyle = nil

		let replacementLength = (transformedBlock as NSString).length
		let replacementRange = NSRange(location: lineRange.location, length: replacementLength)
		if selection.length == 0 {
			let delta = replacementRange.length - lineRange.length
			let newLocation = max(selection.location + delta, lineRange.location)
			setSelectedRange(NSRange(location: newLocation, length: 0))
		} else {
			setSelectedRange(replacementRange)
		}
		return true
	}

	func normalizedLineRange(for selection: NSRange, in text: NSString) -> NSRange {
		var normalized = selection
		if normalized.length > 0 {
			let end = NSMaxRange(normalized)
			if let newline = "\n".utf16.first,
			   end > 0, end <= text.length,
			   text.character(at: end - 1) == newline {
				normalized.length -= 1
			}
		}
		return text.lineRange(for: normalized)
	}

	private func applyIndent(to block: String, indentUnit: String) -> String {
		transformLines(in: block) { line in
			guard !line.isEmpty else {
				return line
			}
			return indentUnit + line
		}
	}

	private func applyOutdent(to block: String, style: IndentStyle) -> String {
		transformLines(in: block) { line in
			switch style {
			case .hardTab:
				if line.hasPrefix("\t") {
					return String(line.dropFirst())
				}
				return line
			case .softSpaces(let width):
				if line.hasPrefix("\t") {
					return String(line.dropFirst())
				}
				let leadingSpaceCount = line.prefix { $0 == " " }.count
				guard leadingSpaceCount > 0 else {
					return line
				}
				return String(line.dropFirst(min(width, leadingSpaceCount)))
			}
		}
	}

	private func transformLines(in block: String, transform: @escaping (String) -> String) -> String {
		let blockText = block as NSString
		let blockRange = NSRange(location: 0, length: blockText.length)
		var transformed = ""
		blockText.enumerateSubstrings(
			in: blockRange,
			options: [.byLines, .substringNotRequired]
		) { _, lineRange, enclosingRange, _ in
			let line = blockText.substring(with: lineRange)
			let suffixRange = NSRange(
				location: NSMaxRange(lineRange),
				length: enclosingRange.length - lineRange.length
			)
			let lineEnding = blockText.substring(with: suffixRange)
			transformed += transform(line) + lineEnding
		}
		return transformed
	}

	// MARK: Indent style detection

	func detectIndentStyle(in text: String) -> IndentStyle {
		if let cached = cachedIndentStyle {
			return cached
		}
		let style = Self.indentStyle(
			of: text, whenUndetectable: defaultIndentation
		)
		cachedIndentStyle = style
		return style
	}

	/// Pure analysis of a document's indentation, split out so it can be tested
	/// without a live text view.
	static func indentStyle(of text: String, whenUndetectable fallback: EditorIndentation) -> IndentStyle {
		let lines = text.split(whereSeparator: \.isNewline)
		let linesToAnalyze = min(lines.count, maxLinesToAnalyzeForIndent)
		var tabIndentedLineCount = 0
		var spaceIndentCounts: [Int: Int] = [:]

		for line in lines.prefix(linesToAnalyze) {
			guard !line.isEmpty else {
				continue
			}
			if line.first == "\t" {
				tabIndentedLineCount += 1
				continue
			}
			let leadingSpaces = countLeadingSpaces(in: line)
			if leadingSpaces >= 2 {
				spaceIndentCounts[leadingSpaces, default: 0] += 1
			}
		}

		let spaceIndentedLineCount = spaceIndentCounts.values.reduce(0, +)
		if tabIndentedLineCount == 0, spaceIndentedLineCount == 0 {
			switch fallback {
			case .tab:        return .hardTab
			case .twoSpaces:  return .softSpaces(2)
			case .fourSpaces: return .softSpaces(4)
			}
		}
		if tabIndentedLineCount > spaceIndentedLineCount {
			return .hardTab
		}
		return .softSpaces(inferredSoftTabWidth(from: spaceIndentCounts) ?? 4)
	}

	private static func countLeadingSpaces(in line: Substring) -> Int {
		var count = 0
		for character in line {
			if character == " " {
				count += 1
				continue
			}
			if character == "\t" {
				count = 0
			}
			break
		}
		return count
	}

	private static let candidateSoftTabWidths = [2, 4, 8]

	/// Infers the indent width from how many indented lines each candidate width
	/// divides evenly.
	private static func inferredSoftTabWidth(from counts: [Int: Int]) -> Int? {
		guard !counts.isEmpty else {
			return nil
		}

		let scores = candidateSoftTabWidths.map { width in
			(width: width, score: counts.reduce(0) { $1.key % width == 0 ? $0 + $1.value : $0 })
		}
		let bestScore = scores.map(\.score).max() ?? 0
		guard bestScore > 0 else {
			// Nothing divides cleanly (a 3-space document, say) — trust the shallowest indent.
			return counts.keys.min()
		}

		// Every depth divisible by 4 is also divisible by 2, so a narrower width can
		// never score lower and would win every tie — which is why 4 and 8 used to be
		// unreachable. Prefer the widest width that still accounts for most of the
		// indented lines. The slack absorbs continuation lines aligned to a bracket;
		// a genuine 2-space document has far more than a fifth of its lines at an
		// odd multiple of 2, so it stays on 2.
		return scores.filter { $0.score * 5 >= bestScore * 4 }.map(\.width).max()
	}
}
