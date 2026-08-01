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
import MopedEditor

/// Glue between the app (preferences, document model) and the `MopedEditor` text
/// view. Owns no editing behavior of its own — it translates preferences and
/// document state into the editor's properties.
@MainActor
final class EditorState: NSObject, ObservableObject {
	let preferences: Preferences
	let supportedLanguages: [String]

	nonisolated(unsafe) private var preferencesObserver: NSObjectProtocol?
	private var activeLanguage: String = "plaintext"

	/// True while SwiftUI is building or updating the NSView tree. `NSTextView`
	/// posts selection changes synchronously, so a programmatic `setPlainText`
	/// during a view pass would otherwise publish from inside that pass.
	private var isPerformingViewUpdate = false

	/// Set while a deferred `cursorPosition` refresh is queued, so a burst of
	/// selection changes during one view pass collapses into a single update.
	private var hasPendingCursorUpdate = false

	@Published var cursorPosition: String = "1:0"

	weak var textView: MopedTextView?
	private weak var model: TextFileModel?

	/// True while the editor's text is being set programmatically (initial build or
	/// `replaceContent`). The text-change delegate checks this to skip echoing the
	/// model's own content back into the model during a SwiftUI view update.
	var isApplyingProgrammaticText: Bool {
		textView?.isApplyingProgrammaticText ?? false
	}

	init(preferences: Preferences = .userShared) {
		self.preferences = preferences
		supportedLanguages = LanguageCatalog.shared.supportedLanguages
		super.init()

		preferencesObserver = NotificationCenter.default.addObserver(
			forName: .preferencesChanged,
			object: nil,
			queue: .main
		) { [weak self] _ in
			MainActor.assumeIsolated {
				self?.applyPreferences()
			}
		}
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
		guard let textView, let window = textView.window else {
			return false
		}
		return (window.firstResponder as AnyObject?) === (textView as AnyObject)
	}

	// MARK: Installation

	/// Builds the editor and configures it from preferences and the document model.
	/// Returns the scroll view for the representable to hand to SwiftUI.
	func makeEditor(model: TextFileModel, delegate: any NSTextViewDelegate) -> NSScrollView {
		duringViewUpdate {
			self.model = model
			activeLanguage = model.docTypeLanguage

			let (scrollView, textView) = MopedTextView.scrollableEditor(
				theme: ThemeCatalog.theme(named: preferences.theme),
				font: preferredFont(at: preferences.fontSizeFloat)
			)

			// Adopt the text view before loading content: `isApplyingProgrammaticText`
			// reads through `textView`, so the guard has to be live during
			// `setPlainText`.
			self.textView = textView

			textView.delegate = delegate
			textView.defaultFontSize = preferences.fontSizeFloat
			textView.defaultIndentation = preferences.selectedDefaultIndentation.editorIndentation
			textView.isHighlightingEnabled = !model.isLargeFile
			textView.wrapsLines = preferences.doLineWrap
			textView.showsLineNumberGutter = preferences.doShowLineNumberRuler
			textView.setPlainText(model.content)
			applyLanguageToEditor(activeLanguage, on: textView)

			updateCursorPosition(for: textView)
			return scrollView
		}
	}

	func replaceContent(with content: String) {
		duringViewUpdate {
			// An external reload can cross the large-file threshold in either direction,
			// and `makeEditor` only ever set this once.
			if let model {
				textView?.isHighlightingEnabled = !model.isLargeFile
			}
			textView?.setPlainText(content)
		}
	}

	/// Marks the span in which SwiftUI owns the call stack (`makeNSView` /
	/// `updateNSView`). Publishing there triggers "Publishing changes from within
	/// view updates", so `updateCursorPosition(for:)` defers instead.
	private func duringViewUpdate<T>(_ body: () -> T) -> T {
		isPerformingViewUpdate = true
		defer { isPerformingViewUpdate = false }
		return body()
	}

	// MARK: Language and preferences

	func applyLanguage(_ language: String) {
		let requested = language.trimmingCharacters(in: .whitespacesAndNewlines)
		let finalLanguage = requested.isEmpty ? "plaintext" : requested
		guard finalLanguage != activeLanguage else {
			return
		}
		activeLanguage = finalLanguage
		guard let textView else {
			return
		}
		applyLanguageToEditor(finalLanguage, on: textView)
	}

	private func applyLanguageToEditor(_ language: String, on textView: MopedTextView) {
		textView.language = language
		textView.lineCommentMarker = language == "plaintext"
			? nil
			: TextFileModel.lineCommentMarker(forLanguage: language)
	}

	private func applyPreferences() {
		guard let textView else {
			return
		}
		textView.theme = ThemeCatalog.theme(named: preferences.theme)
		textView.defaultFontSize = preferences.fontSizeFloat
		textView.editorFont = preferredFont(at: preferences.fontSizeFloat)
		textView.defaultIndentation = preferences.selectedDefaultIndentation.editorIndentation
		textView.wrapsLines = preferences.doLineWrap
		textView.showsLineNumberGutter = preferences.doShowLineNumberRuler
	}

	private func preferredFont(at size: CGFloat) -> NSFont {
		NSFont(name: preferences.font, size: size)
			?? NSFont.userFixedPitchFont(ofSize: size)
			?? NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
	}

	// MARK: Status bar

	func updateCursorPosition(for textView: NSTextView) {
		let nsText = textView.string as NSString
		let location = min(textView.selectedRange().location, nsText.length)
		let preceding = nsText.substring(to: location)
		let components = preceding.components(separatedBy: "\n")
		let position = "\(components.count):\(components.last?.count ?? 0)"

		guard position != cursorPosition else {
			return
		}
		guard !isPerformingViewUpdate else {
			// Re-read after the view pass rather than replaying `position`: replacing
			// the storage moves the selection to the end before `setPlainText`
			// restores it, and publishing that intermediate value would flash the
			// wrong line:column in the status bar.
			scheduleCursorPositionUpdate(for: textView)
			return
		}
		cursorPosition = position
	}

	private func scheduleCursorPositionUpdate(for textView: NSTextView) {
		guard !hasPendingCursorUpdate else {
			return
		}
		hasPendingCursorUpdate = true
		DispatchQueue.main.async { [weak self, weak textView] in
			guard let self else {
				return
			}
			hasPendingCursorUpdate = false
			guard let textView else {
				return
			}
			updateCursorPosition(for: textView)
		}
	}
}

private extension Preferences.DefaultIndentation {
	var editorIndentation: EditorIndentation {
		switch self {
		case .tab:        return .tab
		case .twoSpaces:  return .twoSpaces
		case .fourSpaces: return .fourSpaces
		}
	}
}
