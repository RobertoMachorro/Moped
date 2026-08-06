//
//  SampleFileTests.swift
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

import XCTest
@testable import MopedEditor

/// Runs the tokenizers over the real fixtures in `TestFiles/`, which exist for the manual
/// checklist and were otherwise never machine-checked.
///
/// The assertion is not about *which* token each construct gets — that would need rewriting
/// every time a sample gains a line. It is about the carry state the tokenizer is left
/// holding after the final line, which is the exact signature of a runaway: an unterminated
/// heredoc, an escaped quote that eats its closing delimiter, or a char literal that opens a
/// string all end with the tokenizer still inside that construct at end of file. A
/// well-formed sample must come out the other side in a neutral state.
///
/// A share-of-the-document heuristic was tried first and rejected: it passed against the
/// known-broken tokenizers, because these runaways start near the end of their sample and so
/// never covered enough of the file to trip a ratio. Checked against those same tokenizers,
/// this version names all three multi-line escapes — the PHP and bash heredocs and the Rust
/// char literal that opened a string.
///
/// What it cannot see is a runaway confined to one line, so the CSS `//`-inside-`url()` bug
/// is *not* covered here; `TokenizerRegressionTests` asserts that one directly.
final class SampleFileTests: XCTestCase {
	/// Repo root, derived from this file's location rather than a bundle resource: the
	/// fixtures belong to the repository and the manual checklist, not to the package.
	private static let languagesDirectory = URL(fileURLWithPath: #filePath)
		.deletingLastPathComponent()  // MopedEditorTests
		.deletingLastPathComponent()  // Tests
		.deletingLastPathComponent()  // MopedEditor
		.deletingLastPathComponent()  // repo root
		.appendingPathComponent("TestFiles/Languages", isDirectory: true)

	/// Extension → registry name, for the samples whose extension is not the language id.
	private static let languageForExtension: [String: String] = [
		"c": "c", "cpp": "cpp", "cs": "cs", "css": "css", "diff": "diff", "go": "go",
		"html": "html", "java": "java", "js": "javascript", "json": "json", "jsx": "jsx",
		"md": "markdown", "php": "php", "py": "python", "rb": "ruby", "rs": "rust",
		"sh": "bash", "sql": "sql", "swift": "swift", "toml": "toml", "ts": "typescript",
		"tsx": "tsx", "xml": "xml", "yaml": "yaml"
	]

	func testEverySampleHasAKnownLanguage() throws {
		let names = try FileManager.default
			.contentsOfDirectory(atPath: Self.languagesDirectory.path)
			.filter { $0.hasPrefix("Sample.") }
			.sorted()
		XCTAssertFalse(names.isEmpty, "no samples found at \(Self.languagesDirectory.path)")

		for name in names {
			let ext = (name as NSString).pathExtension
			guard let language = Self.languageForExtension[ext] else {
				XCTFail("\(name) has no language mapping — add it here and to the registry")
				continue
			}
			XCTAssertNotNil(
				LanguageRegistry.tokenizer(for: language),
				"\(name) maps to \(language), which has no tokenizer"
			)
		}
	}

	/// No sample may leave the tokenizer mid-construct at end of file. These files
	/// deliberately carry what causes that: escaped quotes, raw and multi-line strings,
	/// heredocs, char literals holding a quote, and nested block comments.
	func testNoSampleLeavesTheTokenizerMidConstruct() throws {
		for (name, language) in try Self.mappedSamples() {
			let url = Self.languagesDirectory.appendingPathComponent(name)
			let text = try String(contentsOf: url, encoding: .utf8)
			guard let tokenizer = LanguageRegistry.tokenizer(for: language) else {
				continue
			}

			let finalState = Self.stateAfterLastLine(of: text, using: tokenizer)
			XCTAssertTrue(
				Self.isSettled(finalState),
				"""
				\(name): the \(language) tokenizer ends the file still inside \
				\(finalState) — a multi-line state ran away
				"""
			)
		}
	}

	/// Threads carry state line by line the way `DocumentTokenizer` does, and returns what is
	/// left over after the last line.
	private static func stateAfterLastLine(
		of text: String, using tokenizer: any LineTokenizer
	) -> LineState {
		let nsText = text as NSString
		var state = tokenizer.initialState
		var location = 0
		while location < nsText.length {
			var lineStart = 0
			var lineEnd = 0
			var contentsEnd = 0
			nsText.getLineStart(
				&lineStart, end: &lineEnd, contentsEnd: &contentsEnd,
				for: NSRange(location: location, length: 0)
			)
			let content = nsText.substring(
				with: NSRange(location: lineStart, length: contentsEnd - lineStart)
			)
			(_, state) = tokenizer.tokenize(line: content, carryIn: state)
			location = lineEnd
		}
		return state
	}

	/// `.none` is settled. `.rawOutside` is too: PHP's neutral state is "outside `<?php`",
	/// so a file that closes its tag ends there legitimately.
	private static func isSettled(_ state: LineState) -> Bool {
		switch state {
		case .none, .rawOutside:
			return true
		default:
			return false
		}
	}

	private static func mappedSamples() throws -> [(String, String)] {
		try FileManager.default
			.contentsOfDirectory(atPath: languagesDirectory.path)
			.filter { $0.hasPrefix("Sample.") }
			.sorted()
			.compactMap { name in
				languageForExtension[(name as NSString).pathExtension].map { (name, $0) }
			}
	}
}
