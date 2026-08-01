//
//  MopedTextView.swift
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

/// Indentation to use when a document gives no evidence of its own style.
public enum EditorIndentation: Sendable {
	case tab
	case twoSpaces
	case fourSpaces
}

/// The editor: an `NSTextView` on an explicit TextKit 1 stack, with syntax
/// highlighting, a line-number gutter, and Moped's editing behaviors. Everything
/// it needs is set through its own properties — it knows nothing about the app.
public final class MopedTextView: NSTextView {
	private let highlighter: SyntaxHighlighter
	private var lineNumberRuler: LineNumberRulerView?
	var cachedIndentStyle: IndentStyle?

	/// Band painted behind the caret's line on the last draw, so a caret move can
	/// invalidate just the line it left. See `MopedTextView+CurrentLine`.
	var highlightedCaretLineRect: NSRect?

	/// Set while `setPlainText(_:)` is replacing the content, so hosts can tell
	/// programmatic edits from user typing.
	public private(set) var isApplyingProgrammaticText = false

	/// Line-comment marker for the current language (`//`, `#`, …). Toggling
	/// comments beeps when this is nil.
	public var lineCommentMarker: String?

	/// Fallback indentation when a document has no detectable style.
	public var defaultIndentation: EditorIndentation = .tab {
		didSet { cachedIndentStyle = nil }
	}

	/// Size restored by `fontSizeResetMenuItemSelected(_:)`.
	public var defaultFontSize: CGFloat = 13.0

	public var theme: MopedTheme {
		didSet { applyTheme() }
	}

	/// Language name (id or alias, e.g. `swift`, `shell`). Unknown names, including
	/// `plaintext`, render without highlighting.
	public var language: String {
		didSet {
			guard language != oldValue else {
				return
			}
			highlighter.setLanguage(language)
		}
	}

	/// Turned off for large files; clears all coloring while off.
	public var isHighlightingEnabled: Bool {
		get { highlighter.isEnabled }
		set { highlighter.isEnabled = newValue }
	}

	public var showsLineNumberGutter: Bool = false {
		didSet { applyRulerVisibility() }
	}

	public var wrapsLines: Bool = true {
		didSet { applyContainerSizing() }
	}

	/// The editor font. Applied to existing text, typing attributes, and the gutter.
	public var editorFont: NSFont {
		didSet { applyFont() }
	}

	// MARK: Construction

	/// Builds the editor inside a configured scroll view. This is the only supported
	/// way to create a `MopedTextView`.
	public static func scrollableEditor(
		theme: MopedTheme = .defaultLight,
		font: NSFont? = nil
	) -> (scrollView: NSScrollView, textView: MopedTextView) {
		let resolvedFont = font
			?? NSFont.userFixedPitchFont(ofSize: 13.0)
			?? NSFont.monospacedSystemFont(ofSize: 13.0, weight: .regular)

		let scrollView = NSScrollView()
		scrollView.borderType = .noBorder
		scrollView.hasVerticalScroller = true
		scrollView.hasHorizontalScroller = false
		scrollView.autohidesScrollers = true
		scrollView.drawsBackground = true
		scrollView.wantsLayer = true
		scrollView.layer?.masksToBounds = true
		scrollView.findBarPosition = .aboveContent

		let textView = MopedTextView(theme: theme, font: resolvedFont)
		scrollView.documentView = textView
		textView.installLineNumberRuler()
		textView.applyTheme()
		textView.applyContainerSizing()
		return (scrollView, textView)
	}

	private init(theme: MopedTheme, font: NSFont) {
		self.theme = theme
		self.editorFont = font
		self.language = "plaintext"
		self.highlighter = SyntaxHighlighter(theme: theme)

		// Explicit TextKit 1 stack: temporary attributes (used for token colors) and
		// the NSRulerView gutter both depend on NSLayoutManager.
		let textStorage = NSTextStorage()
		let layoutManager = NSLayoutManager()
		let textContainer = NSTextContainer(size: CGSize(width: 0, height: CGFloat.greatestFiniteMagnitude))
		textStorage.addLayoutManager(layoutManager)
		layoutManager.addTextContainer(textContainer)
		layoutManager.allowsNonContiguousLayout = true
		textContainer.widthTracksTextView = true

		super.init(frame: .zero, textContainer: textContainer)

		isRichText = false
		importsGraphics = false
		allowsUndo = true
		isEditable = true
		isSelectable = true
		isAutomaticQuoteSubstitutionEnabled = false
		isAutomaticDashSubstitutionEnabled = false
		isAutomaticTextReplacementEnabled = false
		isAutomaticSpellingCorrectionEnabled = false
		isGrammarCheckingEnabled = false
		usesFindBar = true
		isIncrementalSearchingEnabled = true
		isVerticallyResizable = true
		isHorizontallyResizable = false
		autoresizingMask = [.width]
		minSize = CGSize(width: 0, height: 0)
		maxSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
		textContainerInset = CGSize(width: 2, height: 4)
		super.font = editorFont

		highlighter.attach(to: layoutManager, textStorage: textStorage)
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: Content

	/// Replaces the whole document without registering undo, and without the host
	/// seeing it as a user edit.
	public func setPlainText(_ content: String) {
		guard let textStorage else {
			return
		}
		let priorLocation = selectedRange().location
		isApplyingProgrammaticText = true
		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: 0, length: textStorage.length), with: content)
		textStorage.setAttributes(baseAttributes(), range: NSRange(location: 0, length: textStorage.length))
		textStorage.endEditing()
		isApplyingProgrammaticText = false

		setSelectedRange(NSRange(location: min(priorLocation, textStorage.length), length: 0))
		// The new content may use a different indentation style than the file it
		// replaced (reload / force-reload), so drop the cached analysis.
		cachedIndentStyle = nil
		lineNumberRuler?.invalidateLineNumbers()
		// Whole-document replacement: the per-line caret invalidation in
		// `setSelectedRanges` is not enough here.
		needsDisplay = true
	}

	// MARK: Menu actions

	@IBAction public func fontSizeIncreaseMenuItemSelected(_ sender: Any?) {
		editorFont = NSFontManager.shared.convert(editorFont, toSize: editorFont.pointSize + 1.0)
	}

	@IBAction public func fontSizeDecreaseMenuItemSelected(_ sender: Any?) {
		let newSize = editorFont.pointSize - 1.0
		guard newSize > 2 else {
			NSSound.beep()
			return
		}
		editorFont = NSFontManager.shared.convert(editorFont, toSize: newSize)
	}

	@IBAction public func fontSizeResetMenuItemSelected(_ sender: Any?) {
		editorFont = NSFontManager.shared.convert(editorFont, toSize: defaultFontSize)
	}

	@IBAction public func toggleLineCommentMenuItemSelected(_ sender: Any?) {
		_ = toggleLineComment()
	}

	// MARK: Appearance

	private func applyTheme() {
		highlighter.theme = theme
		backgroundColor = theme.background
		textColor = theme.foreground
		insertionPointColor = Self.caretColor(using: theme.background)
		selectedTextAttributes = [.backgroundColor: theme.selection]
		typingAttributes = baseAttributes()
		enclosingScrollView?.backgroundColor = theme.background
		textStorage?.addAttribute(
			.foregroundColor,
			value: theme.foreground,
			range: NSRange(location: 0, length: textStorage?.length ?? 0)
		)
		lineNumberRuler?.theme = theme
		needsDisplay = true
	}

	private func applyFont() {
		font = editorFont
		typingAttributes = baseAttributes()
		if let textStorage {
			textStorage.addAttribute(
				.font, value: editorFont, range: NSRange(location: 0, length: textStorage.length)
			)
		}
		lineNumberRuler?.numberFont = Self.gutterFont(matching: editorFont)
		lineNumberRuler?.invalidateLineNumbers()
	}

	private func baseAttributes() -> [NSAttributedString.Key: Any] {
		[.font: editorFont, .foregroundColor: theme.foreground]
	}

	private func installLineNumberRuler() {
		guard let scrollView = enclosingScrollView else {
			return
		}
		let ruler = LineNumberRulerView(
			textView: self, theme: theme, numberFont: Self.gutterFont(matching: editorFont)
		)
		scrollView.verticalRulerView = ruler
		scrollView.hasVerticalRuler = true
		lineNumberRuler = ruler
		applyRulerVisibility()
	}

	private func applyRulerVisibility() {
		enclosingScrollView?.rulersVisible = showsLineNumberGutter
		lineNumberRuler?.invalidateLineNumbers()
	}

	/// The classic NSTextView wrap recipe: when wrapping, the container tracks the
	/// view's width; when not, both grow without bound and the scroll view gains a
	/// horizontal scroller.
	private func applyContainerSizing() {
		guard let textContainer, let scrollView = enclosingScrollView else {
			return
		}
		let unbounded = CGFloat.greatestFiniteMagnitude
		if wrapsLines {
			textContainer.widthTracksTextView = true
			textContainer.containerSize = CGSize(width: scrollView.contentSize.width, height: unbounded)
			isHorizontallyResizable = false
			maxSize = CGSize(width: scrollView.contentSize.width, height: unbounded)
			autoresizingMask = [.width]
			frame.size.width = scrollView.contentSize.width
		} else {
			textContainer.widthTracksTextView = false
			textContainer.containerSize = CGSize(width: unbounded, height: unbounded)
			isHorizontallyResizable = true
			maxSize = CGSize(width: unbounded, height: unbounded)
			autoresizingMask = [.width, .height]
		}
		scrollView.hasHorizontalScroller = !wrapsLines
		needsLayout = true
	}

	private static func gutterFont(matching font: NSFont) -> NSFont {
		let size = font.pointSize * 0.9
		return NSFont.userFixedPitchFont(ofSize: size) ?? NSFont.systemFont(ofSize: size)
	}

	/// Caret color as the inverse of the background, matching the previous editor.
	private static func caretColor(using color: NSColor) -> NSColor {
		let resolved = color.usingColorSpace(.sRGB)
			?? color.usingColorSpace(.deviceRGB)
			?? color.usingColorSpace(.genericRGB)

		guard let rgb = resolved else {
			return .black
		}
		var red: CGFloat = 1
		var green: CGFloat = 1
		var blue: CGFloat = 1
		var alpha: CGFloat = 1
		rgb.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
		return NSColor(red: 1 - red, green: 1 - green, blue: 1 - blue, alpha: alpha)
	}

}
