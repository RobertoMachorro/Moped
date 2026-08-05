//
//  IncrementalConsistencyTests.swift
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

/// Applies random edits to a document, maintains highlighting incrementally via
/// `LineStore`, and asserts the accumulated tokens always equal a from-scratch pass.
final class IncrementalConsistencyTests: XCTestCase {
	private let swiftSeed = """
	import AppKit

	/* block
	comment */
	struct Model {
		let title = \"\"\"
		multi \\(line)
		\"\"\"
		func render() -> Bool {
			// note
			return true
		}
	}
	"""

	private let markdownSeed = """
	# Heading

	Some **bold** and `inline` text.

	```swift
	let fenced = 1
	```

	- item
	> quote
	"""

	private let fragments = [
		"\"", "\"\"\"", "/*", "*/", "//", "\n", "let x = 1\n", "`", "```\n", "#", "{", "}",
		" ", "func f() {}", "\\(", ")", "end", "@attr", "<<~EOF\n", "?>", "<?php ",
		"<?xml ", "<![CDATA[", "]]>", "<!--", "-->", "<tag ", "/>"
	]

	func testSwiftRandomEdits() {
		runRandomEdits(language: "swift", seedText: swiftSeed, seed: 42)
	}

	func testMarkdownRandomEdits() {
		runRandomEdits(language: "markdown", seedText: markdownSeed, seed: 7)
	}

	func testRubyRandomEdits() {
		let seedText = "require 'x'\nsql = <<~SQL\n select 1\nSQL\nputs sql\n=begin\nnotes\n=end\n"
		runRandomEdits(language: "ruby", seedText: seedText, seed: 99)
	}

	func testHTMLRandomEdits() {
		let seedText = "<html>\n<!-- c -->\n<div class=\"a\"\n id=\"b\">text &amp; tail</div>\n</html>\n"
		runRandomEdits(language: "html", seedText: seedText, seed: 3)
	}

	func testXMLRandomEdits() {
		let seedText = """
		<?xml version="1.0" encoding="UTF-8"?>
		<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN">
		<plist version="1.0">
			<dict>
				<key>a</key>
				<string>b &amp; c</string>
				<data><![CDATA[ raw > payload
				second line ]]></data>
			</dict>
		</plist>

		"""
		runRandomEdits(language: "xml", seedText: seedText, seed: 17)
	}

	// The languages with the trickiest carry states: PHP's raw boundaries, bash and
	// PHP heredocs, Rust's nesting block comments and raw strings, C#'s verbatim and
	// interpolated strings, Python's and TOML's triple-quoted multiline strings.

	func testPhpRandomEdits() {
		let seedText = """
		<?php
		$greeting = "hello $name";
		/* block
		comment */
		$sql = <<<SQL
		select 1
		SQL;
		echo $greeting;
		?>
		tail text
		"""
		runRandomEdits(language: "php", seedText: seedText, seed: 11)
	}

	func testBashRandomEdits() {
		let seedText = """
		#!/bin/sh
		if [ -n "$HOME" ]; then
			echo "${PATH}"
		fi
		cat <<EOF
		body text
		EOF
		x=$(( 1 << 2 ))
		echo done
		"""
		runRandomEdits(language: "bash", seedText: seedText, seed: 23)
	}

	func testRustRandomEdits() {
		let seedText = """
		fn main() {
			/* outer /* nested */ comment */
			let s = r#"raw "string" here"#;
			let t = "multi
			line";
			println!("{}", s);
		}
		"""
		runRandomEdits(language: "rust", seedText: seedText, seed: 31)
	}

	func testCSharpRandomEdits() {
		let seedText = """
		using System;
		class P {
			static void Main() {
				var v = @"verbatim ""quoted""
				spanning";
				var i = $"count {v.Length}";
				/* block
				comment */
			}
		}
		"""
		runRandomEdits(language: "cs", seedText: seedText, seed: 47)
	}

	func testPythonRandomEdits() {
		let seedText = """
		import os
		def f():
			'''triple
			quoted'''
			s = "one"
			# comment
			return f"{s}!"
		"""
		runRandomEdits(language: "python", seedText: seedText, seed: 53)
	}

	func testTomlRandomEdits() {
		let seedText = """
		[table]
		key = "value"
		multi = \"\"\"
		spans
		lines
		\"\"\"
		# comment
		nums = [1, 2, 3]
		"""
		runRandomEdits(language: "toml", seedText: seedText, seed: 61)
	}

	private func runRandomEdits(language: String, seedText: String, seed: UInt64, iterations: Int = 120) {
		guard let tokenizer = LanguageRegistry.tokenizer(for: language) else {
			XCTFail("No tokenizer for \(language)")
			return
		}
		var rng = SeededGenerator(seed: seed)
		var text = seedText as NSString
		var store = LineStore(tokenizer: tokenizer)
		store.reset(text: text)
		var accumulated = applyPass(&store, text: text, current: [])

		for iteration in 0..<iterations {
			let mutable = NSMutableString(string: text as String)
			let editStart: Int
			let deletedLength: Int
			let insertedLength: Int
			if mutable.length > 0 && Int.random(in: 0..<3, using: &rng) == 0 {
				// Delete a small random range.
				let location = Int.random(in: 0..<mutable.length, using: &rng)
				let maxLength = min(mutable.length - location, 12)
				var range = NSRange(location: location, length: Int.random(in: 1...max(1, maxLength), using: &rng))
				range = mutable.rangeOfComposedCharacterSequences(for: range)
				mutable.deleteCharacters(in: range)
				editStart = range.location
				deletedLength = range.length
				insertedLength = 0
			} else {
				let location = Int.random(in: 0...mutable.length, using: &rng)
				let safeLocation = location == mutable.length
					? location
					: mutable.rangeOfComposedCharacterSequences(for: NSRange(location: location, length: 0)).location
				let inserted = fragments[Int.random(in: 0..<fragments.count, using: &rng)]
				mutable.insert(inserted, at: safeLocation)
				editStart = safeLocation
				deletedLength = 0
				insertedLength = (inserted as NSString).length
			}

			text = NSString(string: mutable as String)
			// Shift surviving tokens the way attribute storage would.
			accumulated = shift(
				accumulated, editStart: editStart, deletedLength: deletedLength, insertedLength: insertedLength
			)
			let edited = NSRange(location: editStart, length: insertedLength)
			store.noteEdit(in: text, editedRange: edited, changeInLength: insertedLength - deletedLength)
			accumulated = applyPass(&store, text: text, current: accumulated)

			let reference = DocumentTokenizer.tokenize(text as String, using: tokenizer)
			XCTAssertEqual(
				normalize(accumulated), normalize(reference),
				"Divergence at iteration \(iteration) for \(language)"
			)
			if normalize(accumulated) != normalize(reference) {
				break
			}
		}
	}

	/// Mimics how attributed-storage ranges move under an edit: tokens before the
	/// edit stay, tokens after shift by the length delta, overlapping tokens drop
	/// (their lines are re-tokenized anyway).
	private func shift(_ tokens: [Token], editStart: Int, deletedLength: Int, insertedLength: Int) -> [Token] {
		let delta = insertedLength - deletedLength
		var result: [Token] = []
		for token in tokens {
			if NSMaxRange(token.range) <= editStart {
				result.append(token)
			} else if token.range.location >= editStart + deletedLength {
				result.append(Token(
					kind: token.kind,
					range: NSRange(location: token.range.location + delta, length: token.range.length)
				))
			}
		}
		return result
	}

	/// Runs highlight passes until the store settles, merging each pass's recolored
	/// tokens over the accumulated set — the same clear-then-reapply the highlighter
	/// does, including its reschedule loop for disjoint dirty regions.
	private func applyPass(_ store: inout LineStore, text: NSString, current: [Token]) -> [Token] {
		var merged = current
		while let result = store.highlightPass(text: text) {
			merged = merged.filter { NSIntersectionRange($0.range, result.recolored).length == 0 }
			merged.append(contentsOf: result.tokens)
		}
		return merged
	}

	private func normalize(_ tokens: [Token]) -> [String] {
		tokens
			.filter { $0.range.length > 0 }
			.sorted { lhs, rhs in
				lhs.range.location != rhs.range.location
					? lhs.range.location < rhs.range.location
					: lhs.range.length < rhs.range.length
			}
			.map { "\($0.range.location):\($0.range.length):\($0.kind.rawValue)" }
	}
}
