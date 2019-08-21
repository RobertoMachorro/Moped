//
//  TextFileModel.swift
//
//  Moped - A general purpose text editor, small and light.
//  Copyright © 2019 Roberto Machorro. All rights reserved.
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

import Foundation

class TextFileModel: NSObject {

	@objc dynamic var content: String
	@objc dynamic var docTypeName: String
	@objc dynamic var docTypeLanguage: String

	public init(content: String, typeName: String, typeLanguage: String) {
		self.content = content
		self.docTypeName = typeName
		self.docTypeLanguage = typeLanguage
	}

}

extension TextFileModel {

	func read(from data: Data, ofType typeName: String) {
		docTypeName = typeName
		docTypeLanguage = getLanguageForType(typeName: docTypeName)
		content = String(data: data, encoding: .utf8) ?? "** UNRECOGNIZED FILE **"
	}

	func data(ofType typeName: String) -> Data? {
		docTypeName = typeName
		docTypeLanguage = getLanguageForType(typeName: docTypeName)
		return content.data(using: .utf8)
	}

}

extension TextFileModel {

	func getLanguageForType(typeName: String) -> String {
		guard let plistPath = Bundle.main.path(forResource: "LanguagesUTI", ofType: "plist"),
			let languagesFromUTI = NSDictionary(contentsOfFile: plistPath),
			let language = languagesFromUTI[typeName] as? String else {
			print("Unknown doctTypeName: \(docTypeName)")
			return "plaintext"
		}
		return language
	}

}
