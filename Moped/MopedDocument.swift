//
//  MopedDocument.swift
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

import Combine
import SwiftUI
import UniformTypeIdentifiers

final class MopedDocument: ReferenceFileDocument, ObservableObject {
	static var readableContentTypes: [UTType] = {
		var types: [UTType] = [
			.plainText,
			.text,
			.html,
			.data
		]

		if let plistPath = Bundle.main.path(forResource: "LanguagesUTI", ofType: "plist"),
			let languagesFromUTI = NSDictionary(contentsOfFile: plistPath) {
			for key in languagesFromUTI.allKeys {
				if let identifier = key as? String {
					types.append(UTType(importedAs: identifier))
				}
			}
		}

		return Array(Set(types))
	}()

	@Published var model: TextFileModel

	struct Snapshot {
		let content: String
		let typeName: String
		let typeLanguage: String
		let encoding: String.Encoding
	}

	private var modelCancellable: AnyCancellable?

	init(content: String = "") {
		model = TextFileModel(
			content: content,
			typeName: "public.plain-text",
			typeLanguage: "plaintext"
		)
		setupModelObservation()
	}

	init(configuration: ReadConfiguration) throws {
		model = TextFileModel(
			content: "",
			typeName: configuration.contentType.identifier,
			typeLanguage: "plaintext"
		)

		guard let data = configuration.file.regularFileContents else {
			throw CocoaError(.fileReadCorruptFile)
		}

		model.read(from: data, ofType: configuration.contentType.identifier)
		setupModelObservation()
	}

	func snapshot(contentType: UTType) throws -> Snapshot {
		Snapshot(
			content: model.content,
			typeName: contentType.identifier,
			typeLanguage: model.docTypeLanguage,
			encoding: model.encoding
		)
	}

	func fileWrapper(snapshot: Snapshot, configuration: WriteConfiguration) throws -> FileWrapper {
		let typeName = configuration.contentType.identifier
		let snapshotModel = TextFileModel(
			content: snapshot.content,
			typeName: typeName,
			typeLanguage: snapshot.typeLanguage
		)
		snapshotModel.encoding = snapshot.encoding

		guard let data = snapshotModel.data(ofType: typeName) else {
			throw CocoaError(.fileWriteUnknown)
		}

		return .init(regularFileWithContents: data)
	}

	private func setupModelObservation() {
		modelCancellable = model.objectWillChange.sink { [weak self] _ in
			self?.objectWillChange.send()
		}
	}
}
