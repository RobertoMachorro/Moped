//
//  TokenizerTestHelpers.swift
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

func tokenize(_ text: String, as language: String) -> [Token] {
	guard let tokenizer = LanguageRegistry.tokenizer(for: language) else {
		XCTFail("No tokenizer registered for \(language)")
		return []
	}
	return DocumentTokenizer.tokenize(text, using: tokenizer)
}

/// The token kind covering the first occurrence of `fragment`, or nil.
func kindOfFirst(_ fragment: String, in text: String, as language: String) -> TokenKind? {
	let range = (text as NSString).range(of: fragment)
	guard range.location != NSNotFound else {
		XCTFail("Fragment \(fragment) not found in fixture")
		return nil
	}
	let tokens = tokenize(text, as: language)
	return tokens.first { NSIntersectionRange($0.range, range).length == range.length }?.kind
}

func assertKind(
	_ fragment: String, is kind: TokenKind, in text: String, as language: String,
	file: StaticString = #filePath, line: UInt = #line
) {
	XCTAssertEqual(
		kindOfFirst(fragment, in: text, as: language), kind,
		"Expected \(fragment) to be \(kind.rawValue)", file: file, line: line
	)
}

func assertPlain(
	_ fragment: String, in text: String, as language: String,
	file: StaticString = #filePath, line: UInt = #line
) {
	XCTAssertNil(
		kindOfFirst(fragment, in: text, as: language),
		"Expected \(fragment) to be plain", file: file, line: line
	)
}

/// Deterministic pseudo-random generator for property tests.
struct SeededGenerator: RandomNumberGenerator {
	private var state: UInt64

	init(seed: UInt64) {
		self.state = seed == 0 ? 0x2545F491_4F6CDD1D : seed
	}

	mutating func next() -> UInt64 {
		state ^= state << 13
		state ^= state >> 7
		state ^= state << 17
		return state
	}
}
