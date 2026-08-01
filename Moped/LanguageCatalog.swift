//
//  LanguageCatalog.swift
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

import Foundation
import MopedEditor

/// Names offered in the language pickers: only languages that actually highlight, plus
/// `plaintext` for "no highlighting".
///
/// This used to fold in every value from `LanguagesUTI.plist` as well, listing ~107
/// names when only 21 tokenizers exist — most of the picker did nothing. File types
/// with no tokenizer now resolve to `plaintext` instead, in
/// `TextFileModel.getLanguageForType`.
/// `Sendable` holds trivially: the one stored property is an immutable `[String]`,
/// fixed at init from the registry.
final class LanguageCatalog: Sendable {
	static let shared = LanguageCatalog()

	let supportedLanguages: [String]

	private init() {
		supportedLanguages = (["plaintext"] + LanguageRegistry.selectableNames).sorted()
	}
}
