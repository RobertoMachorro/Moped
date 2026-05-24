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

import AppKit
import Foundation
import STPluginNeon

/// Editor language registry. Names listed here populate the language picker; names that
/// produce a non-nil `NeonPlugin` get Plugin-Neon syntax highlighting, the rest render plain.
final class LanguageCatalog {
	static let shared = LanguageCatalog()

	let supportedLanguages: [String]

	private init() {
		var names = Set<String>(LanguageCatalog.supportedNeonNames)
		if let path = Bundle.main.path(forResource: "LanguagesUTI", ofType: "plist"),
		   let dict = NSDictionary(contentsOfFile: path) as? [String: String] {
			for value in dict.values {
				names.insert(value)
			}
		}
		names.insert("plaintext")
		supportedLanguages = names.sorted()
	}

	/// Builds a NeonPlugin configured for the given language name, or nil if the language
	/// isn't backed by a parser in `STTextView-Plugin-Neon`. `.swift`/`.bash`/etc. are
	/// resolved via type inference against `NeonPlugin.init` so we don't need to import
	/// (the internal) `TreeSitterResource` module here.
	@MainActor
	// swiftlint:disable:next cyclomatic_complexity
	func makeNeonPlugin(for languageName: String, theme: STPluginNeon.Theme) -> NeonPlugin? {
		switch languageName.lowercased() {
		case "bash", "shell":                 return NeonPlugin(theme: theme, language: .bash)
		case "c":                             return NeonPlugin(theme: theme, language: .c)
		case "cpp", "objectivec":             return NeonPlugin(theme: theme, language: .cpp)
		case "cs":                            return NeonPlugin(theme: theme, language: .csharp)
		case "css", "scss", "less":           return NeonPlugin(theme: theme, language: .css)
		case "go":                            return NeonPlugin(theme: theme, language: .go)
		case "html", "htmlbars", "erb",
			 "twig", "handlebars":             return NeonPlugin(theme: theme, language: .html)
		case "java", "kotlin", "groovy":      return NeonPlugin(theme: theme, language: .java)
		case "javascript":                    return NeonPlugin(theme: theme, language: .javascript)
		case "typescript":                    return NeonPlugin(theme: theme, language: .typescript)
		case "json":                          return NeonPlugin(theme: theme, language: .json)
		case "markdown", "asciidoc":          return NeonPlugin(theme: theme, language: .markdown)
		case "php":                           return NeonPlugin(theme: theme, language: .php)
		case "python":                        return NeonPlugin(theme: theme, language: .python)
		case "ruby":                          return NeonPlugin(theme: theme, language: .ruby)
		case "rust":                          return NeonPlugin(theme: theme, language: .rust)
		case "sql":                           return NeonPlugin(theme: theme, language: .sql)
		case "swift":                         return NeonPlugin(theme: theme, language: .swift)
		case "toml":                          return NeonPlugin(theme: theme, language: .toml)
		case "yaml":                          return NeonPlugin(theme: theme, language: .yaml)
		default:                              return nil
		}
	}

	/// Mirror of the language names handled by `makeNeonPlugin` — kept here so the picker
	/// surfaces them even when `LanguagesUTI.plist` has no UTI mapping.
	private static let supportedNeonNames: [String] = [
		"bash", "shell", "c", "cpp", "objectivec", "cs", "css", "scss", "less", "go",
		"html", "htmlbars", "erb", "twig", "handlebars", "java", "kotlin", "groovy",
		"javascript", "typescript", "json", "markdown", "asciidoc", "php", "python",
		"ruby", "rust", "sql", "swift", "toml", "yaml"
	]
}
