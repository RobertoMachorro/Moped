//
//  LanguageRegistry.swift
//
//  MopedEditor - The homegrown text editor core and syntax highlighter used by Moped.
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

/// Lookup from language names (canonical ids and aliases, mirroring the names the
/// app has always used) to tokenizers. Unknown names mean plain text.
public enum LanguageRegistry {
	static let genericDefinitions: [LanguageDefinition] = [
		.swiftLanguage, .cLanguage, .cppLanguage, .csharpLanguage, .javaLanguage,
		.goLanguage, .rustLanguage, .pythonLanguage, .rubyLanguage, .phpLanguage,
		.javascriptLanguage, .typescriptLanguage, .cssLanguage, .jsonLanguage,
		.yamlLanguage, .tomlLanguage, .sqlLanguage, .bashLanguage
	]

	private static let markdownAliases = ["asciidoc"]
	private static let htmlAliases = ["htmlbars", "erb", "twig", "handlebars"]

	/// Canonical id for a language name, or nil when the name isn't highlighted.
	private static let canonicalIDs: [String: String] = {
		var map: [String: String] = ["markdown": "markdown", "html": "html", "xml": "xml"]
		for alias in markdownAliases {
			map[alias] = "markdown"
		}
		for alias in htmlAliases {
			map[alias] = "html"
		}
		for definition in genericDefinitions {
			map[definition.id] = definition.id
			for alias in definition.aliases {
				map[alias] = definition.id
			}
		}
		return map
	}()

	private static let tokenizers: [String: any LineTokenizer] = {
		// XML shares the markup tokenizer with HTML but keeps its own id: the UTI
		// table resolves .xml/.plist/.svg to "xml", and it is not HTML.
		var map: [String: any LineTokenizer] = [
			"markdown": MarkdownTokenizer(),
			"html": HTMLTokenizer(),
			"xml": HTMLTokenizer()
		]
		for definition in genericDefinitions {
			map[definition.id] = GenericTokenizer(language: definition)
		}
		return map
	}()

	/// Every name (id or alias) the highlighter understands.
	public static let supportedNames: [String] = canonicalIDs.keys.sorted()

	public static func canonicalID(for name: String) -> String? {
		canonicalIDs[name.lowercased()]
	}

	public static func tokenizer(for name: String) -> (any LineTokenizer)? {
		canonicalID(for: name).flatMap { tokenizers[$0] }
	}
}
