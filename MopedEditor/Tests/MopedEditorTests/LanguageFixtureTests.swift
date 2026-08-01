//
//  LanguageFixtureTests.swift
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

final class LanguageFixtureTests: XCTestCase {
	func testAllLanguagesRegistered() {
		let expected = [
			"bash", "c", "cpp", "cs", "css", "go", "html", "java", "javascript",
			"json", "markdown", "php", "python", "ruby", "rust", "sql", "swift",
			"toml", "typescript", "xml", "yaml"
		]
		for name in expected {
			XCTAssertNotNil(LanguageRegistry.tokenizer(for: name), "Missing tokenizer for \(name)")
		}
		let aliases = [
			"shell", "objectivec", "scss", "less", "htmlbars", "erb", "twig",
			"handlebars", "kotlin", "groovy", "asciidoc"
		]
		for alias in aliases {
			XCTAssertNotNil(LanguageRegistry.tokenizer(for: alias), "Missing alias \(alias)")
		}
		XCTAssertNil(LanguageRegistry.tokenizer(for: "plaintext"))
	}

	/// Everything offered for selection must actually highlight — that is the whole
	/// point of the list.
	func testEverySelectableNameHighlights() {
		XCTAssertFalse(LanguageRegistry.selectableNames.isEmpty)
		for name in LanguageRegistry.selectableNames {
			XCTAssertNotNil(
				LanguageRegistry.tokenizer(for: name),
				"\(name) is selectable but has no tokenizer"
			)
		}
		XCTAssertFalse(
			LanguageRegistry.selectableNames.contains("plaintext"),
			"plaintext is the app's 'no highlighting' entry, not a registry name"
		)
	}

	/// Aliases users would recognise as their own language stay selectable; collapsing
	/// them onto the backing tokenizer's id would label a Kotlin file `java`.
	func testRecognisableAliasesRemainSelectable() {
		for alias in ["kotlin", "groovy", "objectivec", "scss", "less", "shell"] {
			XCTAssertTrue(
				LanguageRegistry.selectableNames.contains(alias),
				"\(alias) should still be offered"
			)
		}
	}

	/// `htmlbars` resolves — an old preference may still hold it — but is never offered.
	func testDeprecatedAliasResolvesButIsNotSelectable() {
		XCTAssertEqual(LanguageRegistry.canonicalID(for: "htmlbars"), "html")
		XCTAssertNotNil(LanguageRegistry.tokenizer(for: "htmlbars"))
		XCTAssertFalse(LanguageRegistry.selectableNames.contains("htmlbars"))
	}

	func testC() {
		let text = "#include <stdio.h>\nint main(void) {\n\treturn 0; /* done */\n}"
		assertKind("#include", is: .include, in: text, as: "c")
		assertKind("int", is: .type, in: text, as: "c")
		assertKind("main", is: .functionCall, in: text, as: "c")
		assertKind("return", is: .keywordReturn, in: text, as: "c")
		assertKind("/* done */", is: .comment, in: text, as: "c")
	}

	func testCpp() {
		let text = "namespace app {\nclass Widget : public Base {\n\tvoid draw() const override;\n};\n}"
		assertKind("namespace", is: .keyword, in: text, as: "cpp")
		assertKind("Widget", is: .type, in: text, as: "cpp")
		assertKind("draw", is: .functionCall, in: text, as: "cpp")
	}

	func testCSharp() {
		let text = "using System;\nvar name = $\"hi {user.Name}\";\nstring path = @\"C:\\temp\";"
		assertKind("using", is: .include, in: text, as: "cs")
		assertKind("$\"hi ", is: .string, in: text, as: "cs")
		assertKind("@\"C:\\temp\"", is: .string, in: text, as: "cs")
		assertKind("string", is: .type, in: text, as: "cs")
	}

	func testJava() {
		let text = "import java.util.List;\n@Override\npublic int size() {\n\treturn count;\n}"
		assertKind("import", is: .include, in: text, as: "java")
		assertKind("@Override", is: .punctuationSpecial, in: text, as: "java")
		assertKind("size", is: .functionCall, in: text, as: "java")
	}

	func testGo() {
		let text = "package main\nfunc main() {\n\ts := `raw\nstring`\n\tfmt.Println(len(s))\n}"
		assertKind("package", is: .include, in: text, as: "go")
		assertKind("func", is: .keywordFunction, in: text, as: "go")
		assertKind("`raw", is: .string, in: text, as: "go")
		assertKind("len", is: .variableBuiltin, in: text, as: "go")
		assertKind("Println", is: .constructor, in: text, as: "go")
	}

	func testRust() {
		let text = "use std::fmt;\nfn main() {\n\tlet s: &'static str = \"hi\";\n\t#[derive(Debug)]\n\tstruct Point;\n}"
		assertKind("use", is: .include, in: text, as: "rust")
		assertKind("fn", is: .keywordFunction, in: text, as: "rust")
		assertKind("'static", is: .punctuationSpecial, in: text, as: "rust")
		assertKind("#[derive(Debug)]", is: .punctuationSpecial, in: text, as: "rust")
	}

	func testPython() {
		let text = "import os\n@cached\ndef run(self):\n\t'''doc\n\tstring'''\n\treturn None"
		assertKind("import", is: .include, in: text, as: "python")
		assertKind("@cached", is: .include, in: text, as: "python")
		assertKind("def", is: .keywordFunction, in: text, as: "python")
		assertKind("'''doc", is: .string, in: text, as: "python")
		assertKind("None", is: .variableBuiltin, in: text, as: "python")
	}

	func testRuby() {
		let text = "require 'json'\nclass Cart\n\tdef total\n\t\t@items.sum { |i| i.price }\n\tend\nend\nname = \"x #{value} y\""
		assertKind("require", is: .include, in: text, as: "ruby")
		assertKind("def", is: .keywordFunction, in: text, as: "ruby")
		assertKind("@items", is: .variableBuiltin, in: text, as: "ruby")
		assertKind("#{", is: .punctuationSpecial, in: text, as: "ruby")
	}

	func testRubyHeredoc() {
		let text = "sql = <<~SQL\n\tselect 1\nSQL\nputs sql"
		let tokens = tokenize(text, as: "ruby")
		let body = (text as NSString).range(of: "select 1")
		XCTAssertTrue(
			tokens.contains { $0.kind == .string && NSIntersectionRange($0.range, body).length > 0 },
			"Heredoc body must be a string"
		)
		let after = (text as NSString).range(of: "puts sql")
		XCTAssertFalse(
			tokens.contains { $0.kind == .string && NSIntersectionRange($0.range, after).length > 0 },
			"Heredoc must end at its terminator"
		)
	}

	func testPhpBoundaries() {
		let text = "<html>\n<?php\n$name = \"x\";\necho $name;\n?>\n<body>"
		assertKind("<?php", is: .punctuationSpecial, in: text, as: "php")
		assertKind("$name", is: .variable, in: text, as: "php")
		assertKind("echo", is: .keyword, in: text, as: "php")
		assertPlain("<html>", in: text, as: "php")
		assertPlain("<body>", in: text, as: "php")
	}

	func testJavaScript() {
		let text = "import { x } from 'mod';\nconst msg = `count ${items.length}`;\nfunction go() { return this; }"
		assertKind("import", is: .include, in: text, as: "javascript")
		assertKind("`count ", is: .string, in: text, as: "javascript")
		assertKind("${", is: .punctuationSpecial, in: text, as: "javascript")
		assertKind("function", is: .keywordFunction, in: text, as: "javascript")
		assertKind("this", is: .variableBuiltin, in: text, as: "javascript")
	}

	func testTypeScript() {
		let text = "interface User { name: string }\nconst u: User = make<User>();"
		assertKind("interface", is: .keyword, in: text, as: "typescript")
		assertKind("string", is: .type, in: text, as: "typescript")
		assertKind("User", is: .type, in: text, as: "typescript")
	}

	func testCss() {
		let text = ".card {\n\tcolor: #ff0000 !important;\n\tmargin: 4px;\n}\n@media (min-width: 600px) {}"
		assertKind(".card", is: .type, in: text, as: "css")
		assertKind("color", is: .variableBuiltin, in: text, as: "css")
		assertKind("#ff0000", is: .number, in: text, as: "css")
		assertKind("4px", is: .number, in: text, as: "css")
		assertKind("@media", is: .include, in: text, as: "css")
	}

	func testJson() {
		let text = "{\n\t\"name\": \"moped\",\n\t\"count\": 3,\n\t\"ok\": true,\n\t\"extra\": null\n}"
		assertKind("\"name\"", is: .variable, in: text, as: "json")
		assertKind("\"moped\"", is: .string, in: text, as: "json")
		assertKind("3", is: .number, in: text, as: "json")
		assertKind("true", is: .boolean, in: text, as: "json")
		assertKind("null", is: .variableBuiltin, in: text, as: "json")
	}

	func testYaml() {
		let text = "# config\nname: moped\nitems:\n  - path: /tmp\n    deep: true\nanchor: &base value"
		assertKind("# config", is: .comment, in: text, as: "yaml")
		assertKind("name", is: .variable, in: text, as: "yaml")
		assertKind("path", is: .variable, in: text, as: "yaml")
		assertKind("&base", is: .punctuationSpecial, in: text, as: "yaml")
		assertKind("true", is: .boolean, in: text, as: "yaml")
	}

	func testToml() {
		let text = "[package]\nname = \"moped\"\nversion = \"1.0\"\n# note"
		assertKind("[package]", is: .textTitle, in: text, as: "toml")
		assertKind("name", is: .variable, in: text, as: "toml")
		assertKind("\"moped\"", is: .string, in: text, as: "toml")
	}

	func testSql() {
		let text = "SELECT id, name FROM users WHERE age > 21 -- adults\nselect count(*) from t;"
		assertKind("SELECT", is: .keyword, in: text, as: "sql")
		assertKind("FROM", is: .keyword, in: text, as: "sql")
		assertKind("-- adults", is: .comment, in: text, as: "sql")
		assertKind("select", is: .keyword, in: text, as: "sql")
		assertKind("count", is: .functionCall, in: text, as: "sql")
	}

	func testBash() {
		let text = "#!/bin/sh\nif [ -n \"$HOME\" ]; then\n\techo \"${PATH}\"\nfi\ncat <<EOF\nbody text\nEOF\necho finished"
		assertKind("if", is: .keyword, in: text, as: "bash")
		assertKind("$HOME", is: .variableBuiltin, in: text, as: "bash")
		assertKind("${PATH}", is: .variableBuiltin, in: text, as: "bash")
		assertKind("body text", is: .string, in: text, as: "bash")
		assertPlain("finished", in: text, as: "bash")
	}

	func testPhpVariablesInsideStrings() {
		let text = "<?php\n$greeting = \"hello $name and {$user->id}\";\n"
		assertKind("$name", is: .variable, in: text, as: "php")
		assertKind("{$", is: .punctuationSpecial, in: text, as: "php")
	}
}
