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
		} else if let wide = ContentKind.unmarkedWideEncoding(of: data),
			let text = String(data: data, encoding: wide.stringEncoding) {
			// BOM-less UTF-16. This has to be tried before Mac OS Roman, which would
			// otherwise "succeed" and produce a NUL between every character.
			decoded = (text, wide.stringEncoding)
		} else if let text = String(data: data, encoding: .macOSRoman) {
			// Mac OS Roman maps all 256 byte values, so this rung always succeeds and no
			// "could not determine the encoding" rejection is reachable. That is exactly
			// why `ContentKind` has to gate binary files ahead of these decoders — left to
			// itself this rung would turn an executable into mojibake.
			decoded = (text, .macOSRoman)
		} else {
			throw Self.binaryFileError()
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

	/// Languages whose several UTIs would tie under `betterUTI`'s generic rules. Without
	/// an explicit winner the outcome would follow lexicographic order, which picks the
	/// wrong type — `public.mpeg-2-transport-stream` (the `.ts` video type) sorts ahead
	/// of `public.typescript-source`, and the `-header` variants sort ahead of their
	/// `-source` siblings.
	private static let preferredUTIs: [String: String] = [
		"c": "public.c-source",
		"cpp": "public.c-plus-plus-source",
		"objectivec": "public.objective-c-source",
		"typescript": "public.typescript-source",
		"xml": "public.xml"
	]

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
			guard let existing = result[language] else {
				result[language] = uti
				continue
			}
			if betterUTI(uti, than: existing, for: language) {
				result[language] = uti
			}
		}
		return result
	}()

	/// Deterministic tie-break: the preferred table first, then `public.` identifiers
	/// over vendor ones, then lexicographic order so the winner never depends on
	/// per-process dictionary hashing.
	private static func betterUTI(_ candidate: String, than existing: String, for language: String) -> Bool {
		if let preferred = preferredUTIs[language] {
			if existing == preferred {
				return false
			}
			if candidate == preferred {
				return true
			}
		}
		let candidateIsPublic = candidate.hasPrefix("public.")
		let existingIsPublic = existing.hasPrefix("public.")
		if candidateIsPublic != existingIsPublic {
			return candidateIsPublic
		}
		return candidate < existing
	}

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
