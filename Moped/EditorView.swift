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

import SwiftUI

struct EditorView: View {
	@ObservedObject private var document: MopedDocument
	@State private var editorState: EditorState

	init(document: MopedDocument) {
		_document = ObservedObject(wrappedValue: document)
		_editorState = State(initialValue: EditorState())
	}

	var body: some View {
		VStack(spacing: 0) {
			TextEditorRepresentable(model: document.model, state: editorState)
				.frame(maxWidth: .infinity, maxHeight: .infinity)
				.focusedValue(\.documentContent, documentContentBinding)

			Divider()

			HStack(spacing: 12) {
				Text(document.model.docTypeName)
					.font(.system(size: 11))

				Spacer()

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
		}
		.onAppear {
			editorState.applyLanguage(document.model.docTypeLanguage)
		}
	}

	private var languageBinding: Binding<String> {
		Binding(
			get: { document.model.docTypeLanguage },
			set: { newValue in
				document.model.docTypeLanguage = newValue
				editorState.applyLanguage(newValue)
			}
		)
	}

	private var documentContentBinding: Binding<String> {
		Binding(
			get: { document.model.content },
			set: { document.model.content = $0 }
		)
	}
}
