//
//  EditorState.swift
//
//  Moped - A general purpose text editor, small and light.
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

import Cocoa
import Highlightr

final class EditorState: NSObject, ObservableObject {
	let preferences: Preferences
	let textStorage: CodeAttributedString
	let supportedLanguages: [String]
	let availableThemes: [String]

	private var preferencesObserver: NSObjectProtocol?
	private var currentFontSize: CGFloat

	weak var textView: MopedTextView?
	weak var lineNumberRuler: LineNumberRulerView?

	init(preferences: Preferences = .userShared) {
		self.preferences = preferences
		textStorage = CodeAttributedString()
		supportedLanguages = textStorage.highlightr.supportedLanguages().sorted()
		availableThemes = textStorage.highlightr.availableThemes().sorted()
		currentFontSize = preferences.fontSizeFloat
		super.init()

		preferencesObserver = NotificationCenter.default.addObserver(
			forName: Notification.Name(rawValue: "PreferencesChanged"),
			object: nil,
			queue: .main
		) { [weak self] _ in
			self?.applyPreferences()
		}
	}

	deinit {
		if let observer = preferencesObserver {
			NotificationCenter.default.removeObserver(observer)
		}
	}

	func configure(textView: MopedTextView, scrollView: NSScrollView) {
		self.textView = textView
		textView.editorState = self

		if let layoutManager = textView.layoutManager {
			textStorage.addLayoutManager(layoutManager)
		}

		setupLineNumberRuler(in: scrollView, textView: textView)
		applyPreferences()
	}

	func applyLanguage(_ language: String) {
		textStorage.language = language
	}

	func increaseFontSize() {
		currentFontSize += 1.0
		setTheme(to: preferences.theme, fontSize: currentFontSize)
	}

	func decreaseFontSize() {
		let newSize = currentFontSize - 1.0
		if newSize > 2 {
			currentFontSize = newSize
			setTheme(to: preferences.theme, fontSize: currentFontSize)
		} else {
			NSSound.beep()
		}
	}

	func resetFontSize() {
		currentFontSize = preferences.fontSizeFloat
		setTheme(to: preferences.theme, fontSize: currentFontSize)
	}

	func refreshLineNumberRuler() {
		guard let textView = textView,
			let layoutManager = textView.layoutManager,
			let textContainer = textView.textContainer else {
			return
		}

		layoutManager.ensureLayout(for: textContainer)
		lineNumberRuler?.needsDisplay = true
		textView.enclosingScrollView?.verticalRulerView?.needsDisplay = true
	}

	private func applyPreferences() {
		currentFontSize = preferences.fontSizeFloat
		setLineWrap(to: preferences.doLineWrap)
		setLineNumberRulerVisible(preferences.doShowLineNumberRuler)
		setTheme(to: preferences.theme, fontSize: currentFontSize)
	}

	private func setupLineNumberRuler(in scrollView: NSScrollView, textView: NSTextView) {
		let ruler = LineNumberRulerView(textView: textView)
		lineNumberRuler = ruler
		scrollView.hasVerticalRuler = true
		scrollView.verticalRulerView = ruler
		updateLineNumberFont()
	}

	private func setLineNumberRulerVisible(_ visible: Bool) {
		guard let scrollView = textView?.enclosingScrollView else {
			return
		}

		scrollView.hasVerticalRuler = visible
		scrollView.rulersVisible = visible
	}

	private func updateLineNumberFont() {
		guard let ruler = lineNumberRuler else {
			return
		}

		let fontSize = textStorage.highlightr.theme.codeFont.pointSize * 0.9
		ruler.font = NSFont.userFixedPitchFont(ofSize: fontSize)
			?? NSFont.systemFont(ofSize: fontSize)
	}

	private func setLineWrap(to wrapping: Bool) {
		guard let textView = textView else {
			return
		}

		if wrapping {
			textView.enclosingScrollView?.hasHorizontalScroller = false
			textView.isHorizontallyResizable = false
			let giantValue = Double.greatestFiniteMagnitude
			textView.textContainer?.containerSize = .init(width: 480, height: giantValue)
			textView.textContainer?.widthTracksTextView = true
		} else {
			textView.enclosingScrollView?.hasHorizontalScroller = true
			textView.isHorizontallyResizable = true
			textView.autoresizingMask = [.width, .height]
			let giantValue = Double.greatestFiniteMagnitude
			textView.textContainer?.containerSize = .init(width: giantValue, height: giantValue)
			textView.textContainer?.widthTracksTextView = false
		}
	}

	private func setTheme(to theme: String, fontSize: CGFloat) {
		guard let textView = textView else {
			return
		}

		textStorage.highlightr.setTheme(to: theme)
		textStorage.highlightr.theme.codeFont = NSFont(name: preferences.font, size: fontSize)
			?? NSFont.userFixedPitchFont(ofSize: fontSize)
			?? NSFont.systemFont(ofSize: fontSize)
		textView.backgroundColor = textStorage.highlightr.theme.themeBackgroundColor
		textView.insertionPointColor = caretColor(using: textView.backgroundColor)
		updateLineNumberFont()
	}

	private func caretColor(using color: NSColor) -> NSColor {
		// swiftlint:disable:next identifier_name
		var r: CGFloat = 1.0, g: CGFloat = 1.0, b: CGFloat = 1.0
		if color.colorSpace == NSColorSpace.sRGB {
			color.getRed(&r, green: &g, blue: &b, alpha: nil)
		}
		return NSColor(red: 1.0-r, green: 1.0-g, blue: 1.0-b, alpha: 1)
	}
}

final class MopedTextView: NSTextView {
	weak var editorState: EditorState?

	private enum IndentStyle {
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

	private var cachedIndentStyle: IndentStyle?

	private static let maxLinesToAnalyzeForIndent = 1000

	@IBAction func fontSizeIncreaseMenuItemSelected(_ sender: Any?) {
		editorState?.increaseFontSize()
	}

	@IBAction func fontSizeDecreaseMenuItemSelected(_ sender: Any?) {
		editorState?.decreaseFontSize()
	}

	@IBAction func fontSizeResetMenuItemSelected(_ sender: Any?) {
		editorState?.resetFontSize()
	}

	override func didChangeText() {
		super.didChangeText()
		cachedIndentStyle = nil
	}

	override func performKeyEquivalent(with event: NSEvent) -> Bool {
		let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
		guard modifiers == .command,
			let key = event.charactersIgnoringModifiers else {
			return super.performKeyEquivalent(with: event)
		}

		switch key {
		case "[":
			return shiftIndentationRight(false)
		case "]":
			return shiftIndentationRight(true)
		default:
			return super.performKeyEquivalent(with: event)
		}
	}

	private func shiftIndentationRight(_ shouldIndent: Bool) -> Bool {
		guard isEditable else {
			return false
		}

		let text = string as NSString
		let selectedRange = selectedRange()
		let lineRange = normalizedLineRange(for: selectedRange, in: text)
		let style = detectIndentStyle(in: string)
		let indentUnit = style.indentUnit
		let originalBlock = text.substring(with: lineRange)

		let transformedBlock: String
		if shouldIndent {
			transformedBlock = applyIndent(to: originalBlock, indentUnit: indentUnit)
		} else {
			transformedBlock = applyOutdent(to: originalBlock, style: style)
		}

		guard transformedBlock != originalBlock else {
			return true
		}
		guard shouldChangeText(in: lineRange, replacementString: transformedBlock) else {
			return true
		}

		textStorage?.replaceCharacters(in: lineRange, with: transformedBlock)
		didChangeText()

		let replacementLength = (transformedBlock as NSString).length
		let replacementRange = NSRange(location: lineRange.location, length: replacementLength)
		if selectedRange.length == 0 {
			let delta = replacementRange.length - lineRange.length
			let newLocation = max(selectedRange.location + delta, lineRange.location)
			setSelectedRange(NSRange(location: newLocation, length: 0))
		} else {
			setSelectedRange(replacementRange)
		}
		return true
	}

	private func normalizedLineRange(for selectedRange: NSRange, in text: NSString) -> NSRange {
		var normalized = selectedRange
		if normalized.length > 0 {
			let end = NSMaxRange(normalized)
			if end > 0, end <= text.length, text.character(at: end - 1) == 10 {
				normalized.length -= 1
			}
		}
		return text.lineRange(for: normalized)
	}

	private func applyIndent(to block: String, indentUnit: String) -> String {
		transformLines(in: block) { line in
			guard !line.isEmpty else { return line }
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
				let removeCount = min(width, leadingSpaceCount)
				return String(line.dropFirst(removeCount))
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

	private func detectIndentStyle(in text: String) -> IndentStyle {
		if let cached = cachedIndentStyle {
			return cached
		}

		let lines = text.split(whereSeparator: \.isNewline)
		let linesToAnalyze = min(lines.count, Self.maxLinesToAnalyzeForIndent)
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
			var leadingSpaces = 0
			for character in line {
				if character == " " {
					leadingSpaces += 1
					continue
				}
				if character == "\t" {
					leadingSpaces = 0
				}
				break
			}
			if leadingSpaces >= 2 {
				spaceIndentCounts[leadingSpaces, default: 0] += 1
			}
		}

		let spaceIndentedLineCount = spaceIndentCounts.values.reduce(0, +)
		let style: IndentStyle
		if tabIndentedLineCount == 0, spaceIndentedLineCount == 0 {
			style = .hardTab
		} else if tabIndentedLineCount > spaceIndentedLineCount {
			style = .hardTab
		} else {
			let width = inferredSoftTabWidth(from: spaceIndentCounts) ?? 4
			style = .softSpaces(width)
		}

		cachedIndentStyle = style
		return style
	}

	private func inferredSoftTabWidth(from counts: [Int: Int]) -> Int? {
		guard !counts.isEmpty else {
			return nil
		}
		let candidateWidths = [2, 4, 8]
		var bestWidth: Int?
		var bestScore = -1

		for width in candidateWidths {
			var score = 0
			for (leadingSpaces, count) in counts where leadingSpaces % width == 0 {
				score += count
			}
			if score > bestScore {
				bestScore = score
				bestWidth = width
			}
		}

		if bestScore <= 0 {
			return counts.keys.min()
		}
		return bestWidth
	}
}
