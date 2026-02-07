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
		setTheme(to: preferences.theme, fontSize: currentFontSize)
	}

	private func setupLineNumberRuler(in scrollView: NSScrollView, textView: NSTextView) {
		let ruler = LineNumberRulerView(textView: textView)
		lineNumberRuler = ruler
		scrollView.hasVerticalRuler = true
		scrollView.rulersVisible = true
		scrollView.verticalRulerView = ruler
		updateLineNumberFont()
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

	@IBAction func fontSizeIncreaseMenuItemSelected(_ sender: Any?) {
		editorState?.increaseFontSize()
	}

	@IBAction func fontSizeDecreaseMenuItemSelected(_ sender: Any?) {
		editorState?.decreaseFontSize()
	}

	@IBAction func fontSizeResetMenuItemSelected(_ sender: Any?) {
		editorState?.resetFontSize()
	}
}
