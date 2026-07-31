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

	func testDetectsFourSpaces() {
		let text = "def a():\n    x = 1\n    if x:\n        return x\n"
		XCTAssertEqual(MopedTextView.indentStyle(of: text, whenUndetectable: .tab), .softSpaces(4))
	}

	func testDetectsEightSpaces() {
		let text = "int main(void)\n{\n        int x = 1;\n        if (x) {\n                return x;\n        }\n}\n"
		XCTAssertEqual(MopedTextView.indentStyle(of: text, whenUndetectable: .tab), .softSpaces(8))
	}

	/// A wrapped argument aligned to a paren adds an off-grid depth. One stray line
	/// must not drag a 4-space document back down to 2.
	func testStrayAlignmentLineDoesNotDefeatFourSpaces() {
		let text = """
		def a():
		    x = 1
		    y = 2
		    z = 3
		    if x:
		        return call(x,
		      y)
		        pass
		    done = 1
		    more = 2

		"""
		XCTAssertEqual(MopedTextView.indentStyle(of: text, whenUndetectable: .tab), .softSpaces(4))
	}

	/// Depths that are mostly multiples of 4 still mean 2-space when genuine
	/// depth-2 lines are present in numbers.
	func testTwoSpaceDocumentWithDeepNestingStaysTwo() {
		let text = """
		function a() {
		  if (x) {
		    go();
		    go();
		  }
		  if (y) {
		    stop();
		    stop();
		  }
		}

		"""
		XCTAssertEqual(MopedTextView.indentStyle(of: text, whenUndetectable: .tab), .softSpaces(2))
	}

	/// When no candidate width divides any depth, fall back to the shallowest
	/// indent so odd widths still work.
	func testAllOddDepthsUseShallowestIndent() {
		let text = "def a():\n   x = 1\n   if x:\n         deep = 1\n"
		XCTAssertEqual(MopedTextView.indentStyle(of: text, whenUndetectable: .tab), .softSpaces(3))
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
