//
//  TokenizerRegressionTests.swift
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

/// Constructs that used to run away — an unterminated string or heredoc state carried past
/// its intended end and coloured the rest of the document. Each case here names the specific
/// input that broke, so a regression fails loudly rather than looking like a style change.
/// Per-language smoke coverage lives in `LanguageFixtureTests`.
final class TokenizerRegressionTests: XCTestCase {
	// MARK: Bash heredoc vs. arithmetic left-shift

	/// Requiring an uppercase delimiter was not enough on its own: shifting by a named
	/// constant is the normal idiom, and `<< MAX` matched `MAX` as a heredoc delimiter, so
	/// everything below became a string.
	func testBashLeftShiftByUppercaseConstantIsNotAHeredoc() {
		let text = "x=$(( 1 << MAX ))\necho after"
		assertPlain("after", in: text, as: "bash")
		let indirect = "y=$(( value << BITS ))\necho trailing"
		assertPlain("trailing", in: indirect, as: "bash")
	}

	func testBashHeredocStillOpens() {
		let text = "cat <<EOF\nbody\nEOF\necho after"
		assertKind("body", is: .string, in: text, as: "bash")
		assertPlain("after", in: text, as: "bash")
	}

	// MARK: PHP heredoc terminators

	/// PHP closes a heredoc as part of the surrounding statement, so the terminator line
	/// carries a `;`. Comparing the whole trimmed line to the bare delimiter never matched,
	/// and everything after the heredoc — `?>` included — came out as one string.
	func testPhpHeredocClosesWithTrailingSemicolon() {
		let text = "<?php\n$q = <<<SQL\nSELECT 1\nSQL;\n$after = 42;\n"
		assertKind("SELECT 1", is: .string, in: text, as: "php")
		assertKind("42", is: .number, in: text, as: "php")
	}

	func testPhpHeredocClosesInsideCallArguments() {
		let text = "<?php\nrun(<<<SQL\nSELECT 1\nSQL);\n$after = 42;\n"
		assertKind("SELECT 1", is: .string, in: text, as: "php")
		assertKind("42", is: .number, in: text, as: "php")
	}

	/// A body line that merely starts with the delimiter must not close the heredoc.
	func testPhpHeredocIgnoresDelimiterPrefixInBody() {
		let text = "<?php\n$q = <<<SQL\nSQLX still inside\nSQL;\n$after = 42;\n"
		assertKind("SQLX still inside", is: .string, in: text, as: "php")
		assertKind("42", is: .number, in: text, as: "php")
	}

	// MARK: Rust char literals

	/// Rust had no char-literal rule at all: `'a'` came out plain, and the `"` inside `'"'`
	/// opened a multiline string that ran to the end of the document.
	func testRustCharLiterals() {
		let text = "fn main() {\n\tlet c = 'a';\n\tlet n = '\\n';\n}"
		assertKind("'a'", is: .string, in: text, as: "rust")
		assertKind("'\\n'", is: .string, in: text, as: "rust")
	}

	func testRustQuoteCharLiteralDoesNotOpenAString() {
		let text = "fn main() {\n\tlet q = '\"';\n\tlet total = 42;\n}"
		assertKind("'\"'", is: .string, in: text, as: "rust")
		assertKind("42", is: .number, in: text, as: "rust")
	}

	/// Lifetimes must still win over the new char rule — the pre-pass runs first and matches
	/// `'a` without a closing quote, so it must not be re-read as an unterminated char.
	func testRustLifetimesStillHighlight() {
		let text = "struct Holder<'a> {\n\tvalue: &'a str\n}"
		assertKind("'a", is: .punctuationSpecial, in: text, as: "rust")
	}

	// MARK: CSS line comments vs. URLs

	/// `//` is carried only for the scss/less aliases, so it must not fire inside a URL.
	func testCssUrlIsNotAComment() {
		let text = ".a {\n\tbackground: url(http://example.com/a.png);\n\tmargin: 4px;\n}"
		assertKind("4px", is: .number, in: text, as: "css")
		assertPlain("//example.com", in: text, as: "css")
	}

	func testCssProtocolRelativeUrlIsNotAComment() {
		let text = ".a {\n\tbackground: url(//cdn.example.com/a.png);\n\tmargin: 4px;\n}"
		assertKind("4px", is: .number, in: text, as: "css")
	}

	/// The boundary rule must not cost scss its real comments, in any of the positions they
	/// actually appear in.
	func testScssLineCommentsStillHighlight() {
		let leading = ".a {\n\t// note\n\tmargin: 4px;\n}"
		assertKind("// note", is: .comment, in: leading, as: "scss")
		let trailing = ".a {\n\tmargin: 4px; // note\n}"
		assertKind("// note", is: .comment, in: trailing, as: "scss")
		let afterBrace = ".a {// note\n\tmargin: 4px;\n}"
		assertKind("// note", is: .comment, in: afterBrace, as: "scss")
		let afterSemicolon = ".a {\n\tmargin: 4px;// note\n}"
		assertKind("// note", is: .comment, in: afterSemicolon, as: "scss")
		let atLineStart = "// leading note\n.a {\n\tmargin: 4px;\n}"
		assertKind("// leading note", is: .comment, in: atLineStart, as: "scss")
	}
}
