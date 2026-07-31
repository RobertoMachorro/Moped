//
//  IndentStyleTests.swift
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

final class IndentStyleTests: XCTestCase {
	func testDetectsTabs() {
		let text = "func a() {\n\tlet x = 1\n\tlet y = 2\n}"
		XCTAssertEqual(MopedTextView.indentStyle(of: text, whenUndetectable: .fourSpaces), .hardTab)
	}

	/// Ported behavior: candidate widths are scored by how many indent depths they
	/// divide, and the smallest winner takes ties. Every 4-space depth is also a
	/// multiple of 2, so a 4-space document is reported as 2-space.
	func testFourSpaceDocumentIsReportedAsTwo() {
		let text = "def a():\n    x = 1\n    if x:\n        return x\n"
		XCTAssertEqual(MopedTextView.indentStyle(of: text, whenUndetectable: .tab), .softSpaces(2))
	}

	func testDetectsTwoSpaces() {
		let text = "root:\n  key: 1\n  list:\n    - a\n    - b\n"
		XCTAssertEqual(MopedTextView.indentStyle(of: text, whenUndetectable: .tab), .softSpaces(2))
	}

	func testFallsBackWhenUndetectable() {
		let text = "no indentation here\nnor here\n"
		XCTAssertEqual(MopedTextView.indentStyle(of: text, whenUndetectable: .tab), .hardTab)
		XCTAssertEqual(MopedTextView.indentStyle(of: text, whenUndetectable: .twoSpaces), .softSpaces(2))
		XCTAssertEqual(MopedTextView.indentStyle(of: text, whenUndetectable: .fourSpaces), .softSpaces(4))
	}

	func testTabsWinWhenMixed() {
		let text = "\ta\n\tb\n\tc\n  d\n"
		XCTAssertEqual(MopedTextView.indentStyle(of: text, whenUndetectable: .tab), .hardTab)
	}

	func testIndentUnit() {
		XCTAssertEqual(MopedTextView.IndentStyle.hardTab.indentUnit, "\t")
		XCTAssertEqual(MopedTextView.IndentStyle.softSpaces(3).indentUnit, "   ")
	}
}
