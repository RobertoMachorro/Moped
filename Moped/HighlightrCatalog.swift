//
//  HighlightrCatalog.swift
//
//  Moped - A general purpose text editor, small and light.
//  Copyright © 2019-2026 Roberto Machorro. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
//

import Foundation
import Highlightr

/// Centralized, lazy caches for Highlightr catalogs so we don't recompute
/// on every view or editor instantiation.
final class HighlightrCatalog {
	static let shared = HighlightrCatalog()

	let supportedLanguages: [String]
	let availableThemes: [String]

	private init() {
		let textStorage = CodeAttributedString()
		let highlightr = textStorage.highlightr
		supportedLanguages = highlightr.supportedLanguages().sorted()
		availableThemes = highlightr.availableThemes().sorted()
	}
}
