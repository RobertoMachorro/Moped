//
//  EditorView.swift
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
import SwiftUI

struct EditorView: View {
	@ObservedObject private var document: MopedDocument
	@StateObject private var editorState: EditorState

	init(document: MopedDocument) {
		_document = ObservedObject(wrappedValue: document)
		_editorState = StateObject(wrappedValue: EditorState())
	}

	var body: some View {
		VStack(spacing: 0) {
			TextEditorRepresentable(model: document.model, state: editorState)
				.frame(maxWidth: .infinity, maxHeight: .infinity)
				.clipped()
				.focusedValue(\.documentContent, documentContentBinding)
				.onAppear {
					DispatchQueue.main.async {
						applyFileType(document.model.docTypeName)
					}
				}
				// The first save of an untitled document adopts the type chosen in the Save
				// panel, which changes the language underneath the editor. The picker and the
				// status bar read the model directly; the text view has to be told.
				.onChange(of: document.model.docTypeLanguage) { _, newValue in
					editorState.applyLanguage(newValue)
				}

			HStack(spacing: 12) {
				Text(document.model.docTypeName)
					.font(.system(size: 11))

				Spacer()

				Text(editorState.cursorPosition)
					.font(.system(size: 11).monospacedDigit())
					.padding(.trailing, 8)

				Picker("", selection: languageBinding) {
					ForEach(editorState.supportedLanguages, id: \.self) { language in
						Text(language)
					}
				}
				.labelsHidden()
				.frame(width: 160)
			}
			.padding(.horizontal, 10)
			.frame(height: 20)
			.background(Color(nsColor: .windowBackgroundColor))
		}
		.alert("alert.file_changed.title", isPresented: $document.hasExternalChange) {
			Button("alert.file_changed.button_keep", role: .cancel) { document.hasExternalChange = false }
			Button("alert.file_changed.button_reload") { document.reloadFromDisk() }
		} message: {
			Text("alert.file_changed.message")
		}
		.alert(
			// Neutral title: `reloadFailure` carries the specific reason, which is
			// either the size limit or an undecodable encoding.
			"alert.reload_refused.title",
			isPresented: Binding(
				get: { document.reloadFailure != nil },
				set: { if !$0 { document.reloadFailure = nil } }
			)
		) {
			Button("alert.reload_refused.button_ok", role: .cancel) { document.reloadFailure = nil }
		} message: {
			Text(document.reloadFailure ?? "")
		}
	}

	private var languageBinding: Binding<String> {
		Binding(
			get: { document.model.docTypeLanguage },
			set: { newValue in
				let utTypeId = TextFileModel.getUTTypeForLanguage(newValue)
				document.model.docTypeName = utTypeId
				document.model.docTypeLanguage = newValue
				editorState.applyLanguage(newValue)
				applyFileType(utTypeId)
			}
		)
	}

	/// Writes the type onto *this* view's document, which is what the Save panel reads to
	/// preselect its File Type popup. `currentDocument` is whichever document is frontmost,
	/// which is not necessarily this one — during the launch-time reopen, several documents
	/// are opened in a row while another is key.
	private func applyFileType(_ typeName: String, attempt: Int = 0) {
		guard let nsDocument = hostingNSDocument else {
			// An untitled document is only reachable through its window, and `onAppear` can
			// run before the text view has one. Same bounded retry as the initial-focus
			// path in `TextEditorRepresentable.Coordinator`.
			guard attempt < 10 else {
				return
			}
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
				applyFileType(typeName, attempt: attempt + 1)
			}
			return
		}
		nsDocument.fileType = typeName
	}

	/// By URL when there is one — exact, and independent of the view being in a window.
	/// An untitled document has no URL, so it is found through the window hosting this
	/// editor, which is the same pairing `AppDelegate` does in the other direction.
	private var hostingNSDocument: NSDocument? {
		if let url = document.fileURL {
			return NSDocumentController.shared.document(for: url)
		}
		return editorState.textView?.window?.windowController?.document as? NSDocument
	}

	private var documentContentBinding: Binding<String> {
		Binding(
			get: { document.model.content },
			set: { document.model.content = $0 }
		)
	}
}
