//
//  TextFileModel.swift
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
import Foundation
import MopedEditor
import UniformTypeIdentifiers

class TextFileModel: NSObject, ObservableObject {
	@Published var content: String
	@Published var docTypeName: String
	@Published var docTypeLanguage: String
	var encoding: String.Encoding
	var isLargeFile: Bool = false
	var programmaticChangeID: Int = 0
	var isForceReload: Bool = false

	public init(content: String, typeName: String, typeLanguage: String) {
		self.content = content
		docTypeName = typeName
		docTypeLanguage = typeLanguage
		encoding = .utf8
	}
}

extension TextFileModel {
	/// Rejection for data no encoding could decode. Throwing rather than substituting
	/// placeholder text is deliberate: a placeholder leaves an editable document whose
	/// next save would write the placeholder over the user's file.
	/// Both keys carry the same sentence on purpose. `NSDocumentController` throws away
	/// `NSLocalizedDescriptionKey` when it opens a file — it substitutes its own
	/// "The document ... could not be opened" wrapper — and shows only the recovery
	/// suggestion, so the open alert needs the message there. The reload path in
	/// `MopedDocument.reloadFromDisk` reads `error.localizedDescription`, which is the
	/// description key. Dropping either one silently loses the message on one path.
	private static func readError(_ code: CocoaError.Code, message: String) -> Error {
		CocoaError(code, userInfo: [
			NSLocalizedDescriptionKey: message,
			NSLocalizedRecoverySuggestionErrorKey: message
		])
	}

	static func unknownEncodingError() -> Error {
		readError(.fileReadUnknownStringEncoding, message: String(localized: "error.file_unknown_encoding.description"))
	}

	/// Rejection for a file that is not text. Moped edits text only, and the decoders
	/// below cannot be trusted to refuse anything — see `ContentKind`.
	static func binaryFileError() -> Error {
		readError(.fileReadCorruptFile, message: String(localized: "error.file_binary.description"))
	}

	func read(from data: Data, ofType typeName: String) throws {
		guard ContentKind.of(data) == .text else {
			throw Self.binaryFileError()
		}

		var convertedString: NSString?
		let encodingRaw = NSString.stringEncoding(for: data, encodingOptions: nil, convertedString: &convertedString, usedLossyConversion: nil)

		let decoded: (text: String, encoding: String.Encoding)
		if let convertedString = convertedString as String? {
			// Auto Detected Encoding
			decoded = (convertedString, .init(rawValue: encodingRaw))
			// Otherwise start guessing...
		} else if let text = String(data: data, encoding: .utf8) {
			decoded = (text, .utf8)
		} else if let text = String(data: data, encoding: .macOSRoman) {
			decoded = (text, .macOSRoman)
		} else if let text = String(data: data, encoding: .ascii) {
			decoded = (text, .ascii)
		} else {
			// Nothing is mutated on this path, so a failed reload leaves the open
			// buffer exactly as it was.
			throw Self.unknownEncodingError()
		}

		docTypeName = typeName
		docTypeLanguage = getLanguageForType(typeName: docTypeName)
		content = decoded.text
		encoding = decoded.encoding
		programmaticChangeID &+= 1
	}

	func data(ofType typeName: String) -> Data? {
		docTypeName = typeName
		docTypeLanguage = getLanguageForType(typeName: docTypeName)
		return content.data(using: encoding)
	}
}

extension TextFileModel {
	private static let languagesFromUTI: [String: String] = {
		guard let path = Bundle.main.path(forResource: "LanguagesUTI", ofType: "plist"),
			  let dict = NSDictionary(contentsOfFile: path) as? [String: String] else {
			return [:]
		}
		return dict
	}()

	/// The plist maps far more types than the highlighter supports. Anything without a
	/// tokenizer resolves to `plaintext` so the status-bar picker never shows a name it
	/// cannot offer — a `Picker` whose selection is absent from its options renders
	/// blank. Deprecated names (`htmlbars`) fall back to their canonical id.
	func getLanguageForType(typeName: String) -> String {
		guard let name = Self.languagesFromUTI[typeName] else {
			return "plaintext"
		}
		if LanguageRegistry.selectableNames.contains(name) {
			return name
		}
		return LanguageRegistry.canonicalID(for: name) ?? "plaintext"
	}

	/// Reverse of `languagesFromUTI`, and the source of the type a Save panel preselects.
	///
	/// Identifiers the system cannot resolve are skipped: several plist keys name types
	/// nobody declares (`public.markdown`, `com.unknown.md`), and picking one would hand
	/// out an identifier that is absent from `readableContentTypes` — which is built by
	/// filtering the same keys through `UTType(_:)` — so the save panel would have nothing
	/// to select. Markdown was the one language this actually hit.
	private static let utiFromLanguages: [String: String] = {
		var result: [String: String] = [:]
		for (uti, language) in languagesFromUTI {
			guard UTType(uti) != nil else {
				continue
			}
			if let existing = result[language] {
				if uti.hasPrefix("public.") && !existing.hasPrefix("public.") {
					result[language] = uti
				}
			} else {
				result[language] = uti
			}
		}
		return result
	}()

	static func getUTTypeForLanguage(_ language: String) -> String {
		guard language != "plaintext" else { return "public.plain-text" }
		return utiFromLanguages[language] ?? "public.plain-text"
	}

	private static let lineCommentMarkers: [String: String] = {
		guard let path = Bundle.main.path(forResource: "LanguageComments", ofType: "plist"),
			  let dict = NSDictionary(contentsOfFile: path) as? [String: String] else {
			return [:]
		}
		return dict
	}()

	static func lineCommentMarker(forLanguage language: String) -> String? {
		guard let marker = lineCommentMarkers[language], !marker.isEmpty else {
			return nil
		}
		return marker
	}
}
