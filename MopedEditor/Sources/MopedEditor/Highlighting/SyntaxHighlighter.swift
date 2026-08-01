//
//  SyntaxHighlighter.swift
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

/// Drives incremental highlighting for one text view. Colors are applied as layout
/// manager *temporary attributes*, so they never enter the text storage and can
/// never land on the undo stack or mark the document dirty.
@MainActor
final class SyntaxHighlighter: NSObject, @preconcurrency NSTextStorageDelegate {
	/// Lines re-tokenized per runloop turn. Keeps a document-wide cascade (typing
	/// `/*` at the top of a large file) off the keystroke path.
	private static let linesPerPass = 750

	private weak var layoutManager: NSLayoutManager?
	private weak var textStorage: NSTextStorage?

	private var store: LineStore?
	private var languageName: String?
	private var passScheduled = false

	var theme: MopedTheme {
		didSet { invalidateAll() }
	}

	/// When false the highlighter does nothing — the large-file path.
	var isEnabled = true {
		didSet {
			guard isEnabled != oldValue else {
				return
			}
			// Rebuild (or drop) the line store so re-enabling picks the language back up.
			setLanguage(languageName)
		}
	}

	init(theme: MopedTheme) {
		self.theme = theme
		super.init()
	}

	func attach(to layoutManager: NSLayoutManager, textStorage: NSTextStorage) {
		self.layoutManager = layoutManager
		self.textStorage = textStorage
		textStorage.delegate = self
	}

	/// Switches languages. `nil` (or an unknown name) means plain text.
	func setLanguage(_ name: String?) {
		languageName = name
		let tokenizer = isEnabled ? name.flatMap { LanguageRegistry.tokenizer(for: $0) } : nil
		store = tokenizer.map { LineStore(tokenizer: $0) }
		invalidateAll()
	}

	/// Marks the whole document dirty and schedules a pass.
	func invalidateAll() {
		clearColors()
		guard isEnabled, let textStorage else {
			return
		}
		store?.reset(text: textStorage.string as NSString)
		schedulePass()
	}

	// MARK: NSTextStorageDelegate

	func textStorage(
		_ textStorage: NSTextStorage,
		didProcessEditing editedMask: NSTextStorageEditActions,
		range editedRange: NSRange,
		changeInLength delta: Int
	) {
		guard isEnabled, editedMask.contains(.editedCharacters) else {
			return
		}
		store?.noteEdit(
			in: textStorage.string as NSString, editedRange: editedRange, changeInLength: delta
		)
		schedulePass()
	}

	// MARK: Passes

	private func schedulePass() {
		guard !passScheduled, store != nil else {
			return
		}
		passScheduled = true
		// Never mutate rendering state inside `processEditing`; run after it settles.
		DispatchQueue.main.async { [weak self] in
			self?.runPass()
		}
	}

	private func runPass() {
		passScheduled = false
		guard isEnabled, let textStorage, store != nil else {
			return
		}
		let text = textStorage.string as NSString
		guard let result = store?.highlightPass(text: text, limit: Self.linesPerPass) else {
			return
		}
		apply(tokens: result.tokens, clearing: result.recolored, documentLength: text.length)

		if store?.hasDirtyLines == true {
			schedulePass()
		}
	}

	private func apply(tokens: [Token], clearing range: NSRange, documentLength: Int) {
		guard let layoutManager else {
			return
		}
		let safeRange = NSIntersectionRange(range, NSRange(location: 0, length: documentLength))
		layoutManager.removeTemporaryAttribute(.foregroundColor, forCharacterRange: safeRange)
		for token in tokens {
			let tokenRange = NSIntersectionRange(token.range, safeRange)
			guard tokenRange.length > 0 else {
				continue
			}
			let color = theme.color(for: token.kind)
			guard color != theme.foreground else {
				continue
			}
			layoutManager.addTemporaryAttribute(.foregroundColor, value: color, forCharacterRange: tokenRange)
		}
	}

	private func clearColors() {
		guard let layoutManager, let textStorage else {
			return
		}
		layoutManager.removeTemporaryAttribute(
			.foregroundColor,
			forCharacterRange: NSRange(location: 0, length: textStorage.length)
		)
	}
}
