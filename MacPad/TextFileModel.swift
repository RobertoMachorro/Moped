//
//  TextFileModel.swift
//
//  MacPad - A general purpose text editor, small and light.
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

	@objc dynamic var textString: String
	@objc dynamic var docTypeName: String
	@objc dynamic var docTypeLanguage: String

	public init(textString: String, typeName: String, typeLanguage: String) {
		self.textString = textString
		self.docTypeName = typeName
		self.docTypeLanguage = typeLanguage
	}

}

extension TextFileModel {

	func read(from data: Data, ofType typeName: String) {
		docTypeName = typeName
		docTypeLanguage = getLanguageForType(typeName: docTypeName)
		textString = String(data: data, encoding: .utf8) ?? "** UNRECOGNIZED FILE **"
	}

	func data(ofType typeName: String) -> Data? {
		docTypeName = typeName
		docTypeLanguage = getLanguageForType(typeName: docTypeName)
		return textString.data(using: .utf8)
	}

}

extension TextFileModel {

	func getLanguageForType(typeName: String) -> String {
		switch docTypeName {
		case "public.plain-text":
			return "plaintext"
		case "net.daringfireball.markdown":
			return "markdown"
		case "public.php-script":
			return "php"
		default:
			print("TextFileModel new doctTypeName: \(docTypeName)")
			return "plaintext"
		}
	}

}
