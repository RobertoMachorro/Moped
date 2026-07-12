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

import AppKit
import STTextView
import STPluginNeon
import UniformTypeIdentifiers

// swiftlint:disable file_length

private struct EditorSnapshot {
	let text: String
	let selection: NSRange
	let scrollOrigin: CGPoint?
}

@MainActor
final class EditorState: NSObject, ObservableObject {
	let preferences: Preferences
	let supportedLanguages: [String]
	let availableThemes: [String]

	nonisolated(unsafe) private var preferencesObserver: NSObjectProtocol?
	private var currentFontSize: CGFloat
	private var highlightingEnabled = true
	private var activeLanguage: String = "plaintext"
	private var activeTheme: MopedTheme = .defaultLight

	/// True while the editor's text is being set programmatically (initial build or
	/// `replaceContent`). The text-change delegate checks this to skip echoing the model's
	/// own content back into the model during a SwiftUI view update.
	private(set) var isApplyingProgrammaticText = false

	@Published var cursorPosition: String = "1:0"

	let findPanelController = FindPanelController()
	var findBarContainer: EditorFindBarContainer { findPanelController.container }

	weak var scrollView: NSScrollView?
	weak var textView: MopedTextView?
	weak var delegate: (any STTextViewDelegate)?
	private weak var model: TextFileModel?

	init(preferences: Preferences = .userShared) {
		self.preferences = preferences
		supportedLanguages = LanguageCatalog.shared.supportedLanguages
		availableThemes = MopedTheme.allNames
		currentFontSize = preferences.fontSizeFloat
		activeTheme = MopedTheme.named(preferences.theme)
		super.init()

		preferencesObserver = NotificationCenter.default.addObserver(
			forName: Notification.Name(rawValue: "PreferencesChanged"),
			object: nil,
			queue: .main
		) { [weak self] _ in
			MainActor.assumeIsolated {
				self?.applyPreferences()
			}
		}
	}

	func attachFindPanel(to window: NSWindow?) {
		findPanelController.attach(to: window)
	}

	deinit {
		if let observer = preferencesObserver {
			NotificationCenter.default.removeObserver(observer)
		}
	}

	nonisolated var editorIsFirstResponderForUpdate: Bool {
		MainActor.assumeIsolated { editorIsFirstResponder }
	}

	var editorIsFirstResponder: Bool {
		guard let textView, let window = textView.window else { return false }
		return (window.firstResponder as AnyObject?) === (textView as AnyObject)
	}

	func prepareForLargeFileMode() {
		highlightingEnabled = false
	}

	func installEditor(
		into scrollView: NSScrollView,
		model: TextFileModel,
		delegate: any STTextViewDelegate
	) {
		self.scrollView = scrollView
		self.model = model
		self.delegate = delegate
		activeLanguage = model.docTypeLanguage
		activeTheme = MopedTheme.named(preferences.theme)
		currentFontSize = preferences.fontSizeFloat
		buildTextView(initialContent: model.content)
		setLineWrap(to: preferences.doLineWrap)
		setLineNumberRulerVisible(preferences.doShowLineNumberRuler)
	}

	func replaceContent(with content: String) {
		guard let textView else { return }
		let priorSelection = textView.textSelection
		isApplyingProgrammaticText = true
		textView.text = content
		isApplyingProgrammaticText = false
		let textLength = (content as NSString).length
		let clamped = NSRange(
			location: min(priorSelection.location, textLength),
			length: 0
		)
		textView.textSelection = clamped
		// The new content may use a different indentation style than the file it
		// replaced (reload / force-reload), so drop the cached analysis.
		textView.invalidateIndentStyleCache()
	}

	func applyLanguage(_ language: String) {
		let requested = language.trimmingCharacters(in: .whitespacesAndNewlines)
		let finalLanguage = requested.isEmpty ? "plaintext" : requested
		guard finalLanguage != activeLanguage else { return }
		activeLanguage = finalLanguage
		rebuildTextView()
	}

	func setHighlightingEnabled(_ enabled: Bool) {
		guard enabled != highlightingEnabled else { return }
		highlightingEnabled = enabled
		rebuildTextView()
	}

	func forceLineNumberRulerVisible(_ visible: Bool) {
		setLineNumberRulerVisible(visible)
	}

	func increaseFontSize() {
		currentFontSize += 1.0
		applyFontSize()
	}

	func decreaseFontSize() {
		let newSize = currentFontSize - 1.0
		if newSize > 2 {
			currentFontSize = newSize
			applyFontSize()
		} else {
			NSSound.beep()
		}
	}

	func resetFontSize() {
		currentFontSize = preferences.fontSizeFloat
		applyFontSize()
	}

	func updateCursorPosition(for textView: STTextView) {
		let nsText = (textView.text ?? "") as NSString
		let location = min(textView.textSelection.location, nsText.length)
		let preceding = nsText.substring(to: location)
		let components = preceding.components(separatedBy: "\n")
		cursorPosition = "\(components.count):\(components.last?.count ?? 0)"
	}

	private func applyPreferences() {
		currentFontSize = preferences.fontSizeFloat
		let newTheme = MopedTheme.named(preferences.theme)
		setLineWrap(to: preferences.doLineWrap)
		// Toggling `showsLineNumbers` on STTextView removes the gutter view but doesn't
		// reclaim the space it occupied — the contentView stays offset. Rebuild the
		// text view so the gutter slot collapses cleanly.
		let lineNumbersChanged = (textView?.showsLineNumbers ?? false) != preferences.doShowLineNumberRuler
		if newTheme.name != activeTheme.name || lineNumbersChanged {
			activeTheme = newTheme
			rebuildTextView()
		} else {
			applyFontSize()
		}
	}

	private func currentSnapshot() -> EditorSnapshot {
		EditorSnapshot(
			text: textView?.text ?? model?.content ?? "",
			selection: textView?.textSelection ?? NSRange(location: 0, length: 0),
			scrollOrigin: scrollView?.contentView.bounds.origin
		)
	}

	private func rebuildTextView() {
		let snapshot = currentSnapshot()
		// STTextView installs the gutter as a *floating subview of the scroll view*,
		// not as a subview of the text view itself. Replacing `documentView` leaves
		// the old gutter orphaned and still drawn on top of the new content. Remove
		// it explicitly before building the replacement.
		textView?.gutterView?.removeFromSuperview()
		buildTextView(initialContent: snapshot.text)
		guard let textView else { return }
		let textLength = (snapshot.text as NSString).length
		let clampedLocation = min(snapshot.selection.location, textLength)
		let clampedLength = min(snapshot.selection.length, textLength - clampedLocation)
		textView.textSelection = NSRange(location: clampedLocation, length: clampedLength)
		if let origin = snapshot.scrollOrigin {
			textView.scroll(origin)
		}
	}

	private func buildTextView(initialContent: String) {
		guard let scrollView else { return }

		// Paint the scroll view with the theme color so the area not covered by the
		// text view (empty document, or below short content) doesn't show the default
		// white background.
		scrollView.drawsBackground = true
		scrollView.backgroundColor = activeTheme.background

		let textView = MopedTextView()
		textView.editorState = self
		textView.allowsUndo = true
		textView.isEditable = true
		textView.isSelectable = true
		textView.highlightSelectedLine = true
		textView.showsInvisibleCharacters = false
		textView.textDelegate = delegate

		let font = preferredFont(at: currentFontSize)
		textView.font = font
		textView.textColor = activeTheme.foreground
		textView.backgroundColor = activeTheme.background
		textView.selectedLineHighlightColor = activeTheme.selection
		textView.insertionPointColor = caretColor(using: activeTheme.background)
		textView.typingAttributes = [
			.font: font,
			.foregroundColor: activeTheme.foreground
		]

		scrollView.documentView = textView
		applyContainerSizing(for: preferences.doLineWrap, textView: textView)

		isApplyingProgrammaticText = true
		textView.text = initialContent
		isApplyingProgrammaticText = false

		// showsLineNumbers must come AFTER backgroundColor — STTextView captures the
		// gutter's background from the host's backgroundColor at the moment the gutter
		// is created, and STGutterView.backgroundColor isn't externally writable.
		textView.showsLineNumbers = preferences.doShowLineNumberRuler
		styleGutter(for: textView)

		if highlightingEnabled,
		   let plugin = LanguageCatalog.shared.makeNeonPlugin(
			for: activeLanguage,
			theme: activeTheme.neonTheme(baseFont: font)
		   ) {
			textView.addPlugin(plugin)
		}

		// Redirect the find bar away from the scroll view's accessory slot (which
		// overlays the editor in TextKit 2) into our SwiftUI-hosted container.
		findBarContainer.contentViewReference = textView
		textView.textFinder.findBarContainer = findBarContainer

		self.textView = textView
		updateCursorPosition(for: textView)
	}

	private func applyFontSize() {
		guard let textView else { return }
		let font = preferredFont(at: currentFontSize)
		textView.font = font
		textView.typingAttributes[.font] = font
		styleGutter(for: textView)
	}

	private func styleGutter(for textView: STTextView) {
		guard let gutter = textView.gutterView else { return }
		// STGutterView.backgroundColor isn't externally writable; the gutter inherits its
		// background from textView.backgroundColor at construction time. Only foreground
		// and separator can be tweaked here.
		gutter.textColor = activeTheme.gutterForeground
		gutter.selectedLineTextColor = activeTheme.foreground
		gutter.drawSeparator = true
		let baseSize = currentFontSize * 0.9
		gutter.font = NSFont.userFixedPitchFont(ofSize: baseSize)
			?? NSFont.systemFont(ofSize: baseSize)
	}

	private func preferredFont(at size: CGFloat) -> NSFont {
		NSFont(name: preferences.font, size: size)
			?? NSFont.userFixedPitchFont(ofSize: size)
			?? NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
	}

	private func setLineNumberRulerVisible(_ visible: Bool) {
		textView?.showsLineNumbers = visible
	}

	private func setLineWrap(to wrapping: Bool) {
		guard let textView else { return }
		applyContainerSizing(for: wrapping, textView: textView)
	}

	private func applyContainerSizing(for wrapping: Bool, textView: STTextView) {
		guard let scrollView else { return }
		if wrapping {
			scrollView.hasHorizontalScroller = false
			textView.isHorizontallyResizable = false
		} else {
			scrollView.hasHorizontalScroller = true
			textView.isHorizontallyResizable = true
		}
	}

	private func caretColor(using color: NSColor) -> NSColor {
		let resolved = color.usingColorSpace(.sRGB) ??
			color.usingColorSpace(.deviceRGB) ??
			color.usingColorSpace(.genericRGB)

		if let rgb = resolved {
			var red: CGFloat = 1
			var green: CGFloat = 1
			var blue: CGFloat = 1
			var alpha: CGFloat = 1
			rgb.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
			return NSColor(red: 1 - red, green: 1 - green, blue: 1 - blue, alpha: alpha)
		}

		let cgColor = color.cgColor
		guard let comps = cgColor.components, comps.count >= 3 else {
			return .black
		}
		let luminance = 0.2126 * comps[0] + 0.7152 * comps[1] + 0.0722 * comps[2]
		return luminance > 0.5 ? .black : .white
	}
}

// swiftlint:disable:next type_body_length
final class MopedTextView: STTextView {
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

	@IBAction func toggleLineCommentMenuItemSelected(_ sender: Any?) {
		_ = toggleLineComment()
	}

	func invalidateIndentStyleCache() {
		cachedIndentStyle = nil
	}

	/// Always paste as plain text so attributes from the source app (Xcode colors, RTF
	/// fonts, etc.) don't override the editor's theme/font and so Plugin-Neon can
	/// re-tokenize the inserted content cleanly.
	override func paste(_ sender: Any?) {
		pasteAsPlainText(sender)
	}

	/// `showReplaceInterface` is a no-op when the find bar isn't already visible — it
	/// only toggles the replace row. Ensure the bar is up first so Cmd-Option-F from a
	/// cold start reveals the full find+replace UI.
	///
	/// Also re-asserts our SwiftUI-hosted find bar container before each action.
	/// `NSTextFinder.findBarContainer` is a `weak` reference, so if the container ever
	/// gets nilled out (which is what causes the bar to render as a window title bar
	/// accessory), this puts it back.
	override func performTextFinderAction(_ sender: Any?) {
		if let container = editorState?.findBarContainer {
			textFinder.findBarContainer = container
		}

		let menuItem = sender as? NSMenuItem
		let action = menuItem.flatMap { NSTextFinder.Action(rawValue: $0.tag) }

		if action == .showReplaceInterface,
		   textFinder.findBarContainer?.isFindBarVisible == false {
			textFinder.performAction(.showFindInterface)
		}
		super.performTextFinderAction(sender)

		// NSTextFinder only calls our `isFindBarVisible = true` on the very first show.
		// Subsequent Cmd-F / Cmd-Option-F invocations after an Esc skip us entirely, so
		// the panel stays hidden. Force-present after super for show actions.
		if action == .showFindInterface || action == .showReplaceInterface {
			editorState?.findPanelController.present()
		}
	}

	/// Drag-in counterpart to `paste`. Internal drags (moving selected text within the
	/// same editor) still use STTextView's default path, which preserves our existing
	/// attributes. External drags from other apps bypass the RTF branch so styled text
	/// from Xcode/etc. lands as plain text and is re-tokenized by Plugin-Neon.
	override func performDragOperation(_ sender: any NSDraggingInfo) -> Bool {
		if sender.draggingSource as AnyObject? === self {
			return super.performDragOperation(sender)
		}
		let pasteboard = sender.draggingPasteboard
		if pasteboard.canReadItem(withDataConformingToTypes: [UTType.plainText.identifier]) {
			return readSelection(from: pasteboard, type: .string)
		}
		return false
	}

	override func insertText(_ insertString: Any, replacementRange: NSRange) {
		super.insertText(insertString, replacementRange: replacementRange)
		cachedIndentStyle = nil
	}

	override func insertNewline(_ sender: Any?) {
		let source = text ?? ""
		let nsText = source as NSString
		let selection = textSelection
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
		let indent = nsText.substring(
			with: NSRange(location: lineStart, length: indentEnd - lineStart)
		)
		insertText("\n" + indent, replacementRange: selection)
	}

	override func insertTab(_ sender: Any?) {
		let selection = textSelection
		if selection.length > 0 {
			_ = adjustIndentation(true)
			return
		}

		let style = detectIndentStyle(in: text ?? "")
		switch style {
		case .hardTab:
			super.insertTab(sender)
		case .softSpaces(let width):
			let source = (text ?? "") as NSString
			let searchRange = NSRange(location: 0, length: selection.location)
			let previousNewline = source.range(of: "\n", options: .backwards, range: searchRange)
			let lineStart = previousNewline.location == NSNotFound ? 0 : previousNewline.location + 1
			let column = selection.location - lineStart
			let spacesToInsert = width - (column % width)
			insertText(String(repeating: " ", count: spacesToInsert), replacementRange: selection)
		}
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

	private func toggleLineComment() -> Bool {
		guard isEditable else {
			return false
		}

		let language = editorState?.currentLanguage ?? ""
		guard language != "plaintext",
			  let marker = TextFileModel.lineCommentMarker(forLanguage: language) else {
			NSSound.beep()
			return false
		}

		let source = (text ?? "") as NSString
		let originalSelection = textSelection
		let lineRange = normalizedLineRange(for: originalSelection, in: source)
		let originalBlock = source.substring(with: lineRange)
		let lines = splitBlockIntoLines(originalBlock)
		let nonEmptyIndices = Set(lines.indices.filter { !lines[$0].content.allSatisfy(\.isWhitespace) })

		guard !nonEmptyIndices.isEmpty else {
			NSSound.beep()
			return false
		}

		let allCommented = nonEmptyIndices.allSatisfy { idx in
			lines[idx].content.drop(while: { $0 == " " || $0 == "\t" }).hasPrefix(marker)
		}

		let transformedBlock = allCommented
			? uncommentedBlock(lines: lines, nonEmptyIndices: nonEmptyIndices, marker: marker)
			: commentedBlock(lines: lines, nonEmptyIndices: nonEmptyIndices, marker: marker)

		guard transformedBlock != originalBlock else {
			return true
		}
		guard let textRange = NSTextRange(lineRange, in: textContentManager),
			  shouldChangeText(in: textRange, replacementString: transformedBlock) else {
			return true
		}

		replaceCharacters(in: textRange, with: transformedBlock)
		cachedIndentStyle = nil

		let replacementLength = (transformedBlock as NSString).length
		let replacementRange = NSRange(location: lineRange.location, length: replacementLength)
		if originalSelection.length == 0 {
			let delta = replacementRange.length - lineRange.length
			let newLocation = max(originalSelection.location + delta, lineRange.location)
			textSelection = NSRange(location: newLocation, length: 0)
		} else {
			textSelection = replacementRange
		}
		return true
	}

	private func commentedBlock(
		lines: [(content: String, ending: String)],
		nonEmptyIndices: Set<Int>,
		marker: String
	) -> String {
		let prefix = commonLeadingWhitespace(in: nonEmptyIndices.map { lines[$0].content })
		let insertionOffset = prefix.count
		var result = ""
		for (idx, line) in lines.enumerated() {
			guard nonEmptyIndices.contains(idx) else {
				result += line.content + line.ending
				continue
			}
			let splitAt = line.content.index(line.content.startIndex, offsetBy: insertionOffset)
			result += String(line.content[..<splitAt]) + marker + " " + String(line.content[splitAt...]) + line.ending
		}
		return result
	}

	private func uncommentedBlock(
		lines: [(content: String, ending: String)],
		nonEmptyIndices: Set<Int>,
		marker: String
	) -> String {
		var result = ""
		for (idx, line) in lines.enumerated() {
			guard nonEmptyIndices.contains(idx) else {
				result += line.content + line.ending
				continue
			}
			let leadingCount = line.content.prefix(while: { $0 == " " || $0 == "\t" }).count
			let leadingEnd = line.content.index(line.content.startIndex, offsetBy: leadingCount)
			var rest = String(line.content[leadingEnd...])
			if rest.hasPrefix(marker) {
				rest = String(rest.dropFirst(marker.count))
				if rest.first == " " {
					rest = String(rest.dropFirst())
				}
			}
			result += String(line.content[..<leadingEnd]) + rest + line.ending
		}
		return result
	}

	private func splitBlockIntoLines(_ block: String) -> [(content: String, ending: String)] {
		let blockText = block as NSString
		let blockRange = NSRange(location: 0, length: blockText.length)
		var result: [(content: String, ending: String)] = []
		blockText.enumerateSubstrings(
			in: blockRange,
			options: [.byLines, .substringNotRequired]
		) { _, lineRange, enclosingRange, _ in
			let line = blockText.substring(with: lineRange)
			let suffixRange = NSRange(
				location: NSMaxRange(lineRange),
				length: enclosingRange.length - lineRange.length
			)
			let ending = blockText.substring(with: suffixRange)
			result.append((line, ending))
		}
		return result
	}

	private func commonLeadingWhitespace(in lines: [String]) -> String {
		guard let first = lines.first else {
			return ""
		}
		var prefix = String(first.prefix(while: { $0 == " " || $0 == "\t" }))
		for line in lines.dropFirst() {
			var updated = ""
			for (lhs, rhs) in zip(prefix, line) {
				guard lhs == rhs, lhs == " " || lhs == "\t" else {
					break
				}
				updated.append(lhs)
			}
			prefix = updated
			if prefix.isEmpty {
				break
			}
		}
		return prefix
	}

	private func adjustIndentation(_ shouldIndent: Bool) -> Bool {
		guard isEditable else {
			return false
		}

		let source = (text ?? "") as NSString
		let selection = textSelection
		let lineRange = normalizedLineRange(for: selection, in: source)
		let style = detectIndentStyle(in: text ?? "")
		let indentUnit = style.indentUnit
		let originalBlock = source.substring(with: lineRange)

		let transformedBlock: String
		if shouldIndent {
			transformedBlock = applyIndent(to: originalBlock, indentUnit: indentUnit)
		} else {
			transformedBlock = applyOutdent(to: originalBlock, style: style)
		}

		guard transformedBlock != originalBlock else {
			return true
		}
		guard let textRange = NSTextRange(lineRange, in: textContentManager),
			  shouldChangeText(in: textRange, replacementString: transformedBlock) else {
			return true
		}

		replaceCharacters(in: textRange, with: transformedBlock)
		cachedIndentStyle = nil

		let replacementLength = (transformedBlock as NSString).length
		let replacementRange = NSRange(location: lineRange.location, length: replacementLength)
		if selection.length == 0 {
			let delta = replacementRange.length - lineRange.length
			let newLocation = max(selection.location + delta, lineRange.location)
			textSelection = NSRange(location: newLocation, length: 0)
		} else {
			textSelection = replacementRange
		}
		return true
	}

	private func normalizedLineRange(for selection: NSRange, in text: NSString) -> NSRange {
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

	private func countLeadingSpaces(in line: Substring) -> Int {
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

	private func detectIndentStyle(in text: String) -> IndentStyle {
		if let cached = cachedIndentStyle {
			return cached
		}

		let lines = text.split(whereSeparator: \.isNewline)
		let linesToAnalyze = min(lines.count, Self.maxLinesToAnalyzeForIndent)
		var tabIndentedLineCount = 0
		var spaceIndentCounts: [Int: Int] = [:]

		for line in lines.prefix(linesToAnalyze) {
			guard !line.isEmpty else { continue }
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
		let style: IndentStyle
		if tabIndentedLineCount == 0, spaceIndentedLineCount == 0 {
			switch editorState?.preferences.selectedDefaultIndentation ?? .tab {
			case .tab:        style = .hardTab
			case .twoSpaces:  style = .softSpaces(2)
			case .fourSpaces: style = .softSpaces(4)
			}
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

extension EditorState {
	var currentLanguage: String { activeLanguage }
}
