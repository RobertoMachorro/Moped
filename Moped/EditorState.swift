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

	// Debounced layout coalescing
	private var pendingLayoutWorkItem: DispatchWorkItem?
	private var pendingEditedRange: NSRange?

	private var preferencesObserver: NSObjectProtocol?
	private var currentFontSize: CGFloat
	private var highlightingEnabled = true

	weak var textView: MopedTextView?
	weak var lineNumberRuler: LineNumberRulerView?

	init(preferences: Preferences = .userShared) {
		self.preferences = preferences
		textStorage = CodeAttributedString()
		supportedLanguages = HighlightrCatalog.shared.supportedLanguages
		availableThemes = HighlightrCatalog.shared.availableThemes
		currentFontSize = preferences.fontSizeFloat
		super.init()
		textStorage.delegate = self

		preferencesObserver = NotificationCenter.default.addObserver(
			forName: Notification.Name(rawValue: "PreferencesChanged"),
			object: nil,
			queue: .main
		) { [weak self] _ in
			self?.applyPreferences()
		}
	}

	func prepareForLargeFileMode() {
		highlightingEnabled = false
	}

	deinit {
		if let observer = preferencesObserver {
			NotificationCenter.default.removeObserver(observer)
		}
	}

	func configure(textView: MopedTextView, scrollView: NSScrollView) {
		self.textView = textView
		textView.editorState = self

		if highlightingEnabled, let layoutManager = textView.layoutManager {
			// Ensure the text view uses the Highlightr-backed storage from the start
			layoutManager.replaceTextStorage(textStorage)
		}
		if highlightingEnabled {
			textView.typingAttributes = [:]
		}

		setupLineNumberRuler(in: scrollView, textView: textView)
		applyPreferences()
		if !highlightingEnabled {
			applyPlainStyling(to: textView)
		}

		// If highlighting is enabled and there is already content, schedule a full-range refresh
		if highlightingEnabled, let lm = textView.layoutManager, let ts = lm.textStorage, ts.length > 0, let tc = textView.textContainer {
			let fullRange = NSRange(location: 0, length: ts.length)
			pendingEditedRange = fullRange
			pendingLayoutWorkItem?.cancel()
			let work = DispatchWorkItem { [weak self, weak lm] in
				guard let self = self, let lm = lm else { return }
				let range = self.pendingEditedRange ?? fullRange
				self.pendingEditedRange = nil
				lm.ensureLayout(for: tc)
				lm.invalidateDisplay(forCharacterRange: range)
			}
			pendingLayoutWorkItem = work
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.03, execute: work)
		}

	}

	func applyLanguage(_ language: String) {
		let requested = language.trimmingCharacters(in: .whitespacesAndNewlines)
		let finalLanguage: String
		if !requested.isEmpty, supportedLanguages.contains(requested) {
			finalLanguage = requested
		} else {
			finalLanguage = "swift"
		}
		textStorage.language = finalLanguage
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

	func setHighlightingEnabled(_ enabled: Bool) {
		highlightingEnabled = enabled
		guard let textView = textView else { return }

		ensureTextStorageAttachment(for: textView)

		if enabled {
			applyLanguage(preferences.language)
			setTheme(to: preferences.theme, fontSize: currentFontSize)

			// After enabling highlighting, if there is content, schedule a full-range re-tokenization/refresh
			if let tv = self.textView, let lm = tv.layoutManager, let ts = lm.textStorage, ts.length > 0, let tc = tv.textContainer {
				let fullRange = NSRange(location: 0, length: ts.length)
				// Use the same debounced mechanism to avoid layout during editing
				pendingEditedRange = fullRange
				pendingLayoutWorkItem?.cancel()
				let work = DispatchWorkItem { [weak self, weak lm] in
					guard let self = self, let lm = lm else { return }
					let range = self.pendingEditedRange ?? fullRange
					self.pendingEditedRange = nil
					lm.ensureLayout(for: tc)
					lm.invalidateDisplay(forCharacterRange: range)
				}
				pendingLayoutWorkItem = work
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.03, execute: work)
			}
		} else {
			applyPlainStyling(to: textView)
		}
	}

	func forceLineNumberRulerVisible(_ visible: Bool) {
		setLineNumberRulerVisible(visible)
	}

	private func applyPreferences() {
		currentFontSize = preferences.fontSizeFloat
		if !highlightingEnabled {
			setLineWrap(to: preferences.doLineWrap)
			setLineNumberRulerVisible(preferences.doShowLineNumberRuler)
			if let textView = textView {
				applyPlainStyling(to: textView)
			}
			return
		}
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

	private func ensureTextStorageAttachment(for textView: NSTextView) {
		guard let layoutManager = textView.layoutManager else { return }
		let currentStorage = layoutManager.textStorage

		if highlightingEnabled {
			// Attach Highlightr storage if not already attached
			if currentStorage !== textStorage {
				let existingString = currentStorage?.string ?? textView.string
				currentStorage?.removeLayoutManager(layoutManager)
				textStorage.beginEditing()
				textStorage.setAttributedString(NSAttributedString(string: existingString))
				textStorage.endEditing()
				textStorage.addLayoutManager(layoutManager)
			}
		} else {
			// Ensure we're using a plain storage (not the Highlightr storage)
			if currentStorage === textStorage {
				let existingString = textStorage.string
				textStorage.removeLayoutManager(layoutManager)
				let plain = NSTextStorage()
				plain.beginEditing()
				plain.setAttributedString(NSAttributedString(string: existingString))
				plain.endEditing()
				plain.addLayoutManager(layoutManager)
			}
		}
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
		textView.typingAttributes = [:]
	}

	private func applyPlainStyling(to textView: NSTextView) {
		let font = NSFont(name: preferences.font, size: currentFontSize)
			?? NSFont.userFixedPitchFont(ofSize: currentFontSize)
			?? NSFont.systemFont(ofSize: currentFontSize)
		textView.font = font
		textView.textColor = .textColor
		textView.backgroundColor = .textBackgroundColor
		textView.insertionPointColor = caretColor(using: textView.backgroundColor)
		textView.typingAttributes = [
			.font: font,
			.foregroundColor: NSColor.textColor
		]
	}

	private func caretColor(using color: NSColor) -> NSColor {
		// Resolve dynamic system colors and convert to an RGB color space before extracting components
		let resolved = color.usingColorSpace(.sRGB) ??
					   color.usingColorSpace(.deviceRGB) ??
					   color.usingColorSpace(.genericRGB)

		var r: CGFloat = 1, g: CGFloat = 1, b: CGFloat = 1, a: CGFloat = 1

		if let rgb = resolved {
			var rr: CGFloat = 1, gg: CGFloat = 1, bb: CGFloat = 1, aa: CGFloat = 1
			rgb.getRed(&rr, green: &gg, blue: &bb, alpha: &aa)
			r = rr; g = gg; b = bb; a = aa
			return NSColor(red: 1 - r, green: 1 - g, blue: 1 - b, alpha: a)
		} else {
			// Fallback: compute a contrasting caret color using perceived luminance.
			// If components are unavailable, return a safe default caret color.
			let cg = color.cgColor
			guard let comps = cg.components, comps.count >= 3 else {
				// Safe default when we can't reliably read color components
				return .black
			}
			r = comps[0]; g = comps[1]; b = comps[2]
			let luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b
			return luminance > 0.5 ? .black : .white
		}
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
			return adjustIndentation(false)
		case "]":
			return adjustIndentation(true)
		default:
			return super.performKeyEquivalent(with: event)
		}
	}

	private func adjustIndentation(_ shouldIndent: Bool) -> Bool {
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

extension EditorState: NSTextStorageDelegate {
	func textStorage(_ textStorage: NSTextStorage, didProcessEditing editedMask: NSTextStorageEditActions, range editedRange: NSRange, changeInLength delta: Int) {
		guard let tv = textView else { return }

		// When highlighting is enabled, clear typing attributes so newly inserted text doesn't fight the highlighter.
		// This should also happen for zero-length edits (e.g., attribute-only changes or cursor moves).
		if highlightingEnabled {
			tv.typingAttributes = [:]
		}

		// Debounce layout work to coalesce rapid edits and avoid glyph generation during editing.
		// Only perform layout work when there is a non-zero edited range.
		if editedRange.length > 0, let lm = tv.layoutManager, let tc = tv.textContainer {
			// Merge the edited range with any pending range
			if let existing = pendingEditedRange {
				let newLocation = min(existing.location, editedRange.location)
				let newMax = max(NSMaxRange(existing), NSMaxRange(editedRange))
				pendingEditedRange = NSRange(location: newLocation, length: newMax - newLocation)
			} else {
				pendingEditedRange = editedRange
			}

			// Cancel any pending work
			pendingLayoutWorkItem?.cancel()

			// Schedule a new debounced work item
			let work = DispatchWorkItem { [weak self, weak lm] in
				guard let self = self, let lm = lm else { return }
				let range = self.pendingEditedRange ?? editedRange
				self.pendingEditedRange = nil
				lm.ensureLayout(for: tc)
				lm.invalidateDisplay(forCharacterRange: range)
			}
			pendingLayoutWorkItem = work
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.03, execute: work)
		}
	}
}
