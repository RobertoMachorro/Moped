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

class TextFileModel: NSObject, ObservableObject {
	@Published var content: String
	@Published var docTypeName: String
	@Published var docTypeLanguage: String
	var encoding: String.Encoding

	public init(content: String, typeName: String, typeLanguage: String) {
		self.content = content
		docTypeName = typeName
		docTypeLanguage = typeLanguage
		encoding = .utf8
	}
}

extension TextFileModel {
	func read(from data: Data, ofType typeName: String) {
		docTypeName = typeName
		docTypeLanguage = getLanguageForType(typeName: docTypeName)

		var convertedString: NSString?
		let encodingRaw = NSString.stringEncoding(for: data, encodingOptions: nil, convertedString: &convertedString, usedLossyConversion: nil)

		if let convertedString = convertedString as String? {
			// Auto Detected Encoding
			self.content = convertedString
			self.encoding = .init(rawValue: encodingRaw)
			// Otherwise start guessing...
		} else if let text = String(data: data, encoding: .utf8) {
			content = text
			encoding = .utf8
		} else if let text = String(data: data, encoding: .macOSRoman) {
			content = text
			encoding = .macOSRoman
		} else if let text = String(data: data, encoding: .ascii) {
			content = text
			encoding = .ascii
		} else {
			content = "** UNRECOGNIZED FILE **"
		}
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

	func getLanguageForType(typeName: String) -> String {
		return Self.languagesFromUTI[typeName] ?? "plaintext"
	}
}
