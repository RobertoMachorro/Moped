//
//  FindBarChromeTests.swift
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

/// Issue #101: over a dark theme the find bar showed nothing but its search field. AppKit
/// paints the bar over the editor's own background colour, and its controls are drawn in
/// the window's appearance — dark controls on a black theme, which is nothing at all.
///
/// `NSTextFinder` builds the bar and hands it to the container through `findBarView`, which
/// is exactly what these tests do — no text finder needed, so they stay headless. The bar
/// AppKit builds nests its controls a few levels down, so the fixtures here nest too: the
/// nesting is the point, not incidental.
@MainActor
final class FindBarChromeTests: EditorTestCase {
	func testFindBarBuiltUnderADarkThemeIsDressedDark() throws {
		let (scrollView, _) = makeEditor(theme: .turbo)
		let (findBar, _) = nestedBar()
		try scroll(scrollView).findBarView = findBar

		XCTAssertEqual(findBar.appearance?.name, .darkAqua)
		XCTAssertEqual(scrollView.scrollerKnobStyle, .light)
	}

	func testFindBarBuiltUnderALightThemeIsDressedLight() throws {
		let (scrollView, _) = makeEditor(theme: .defaultLightPalette)
		let (findBar, _) = nestedBar()
		try scroll(scrollView).findBarView = findBar

		XCTAssertEqual(findBar.appearance?.name, .aqua)
		XCTAssertEqual(scrollView.scrollerKnobStyle, .dark)
	}

	/// The one that matters. Setting the appearance on the bar's root leaves the controls
	/// untouched, because AppKit pins the appearance of the banner in between — which is
	/// exactly the bug in #101, and exactly what a "simplification" back to a single
	/// assignment would reintroduce.
	func testEveryControlInsideTheBarIsDressedNotJustItsRoot() throws {
		let (scrollView, _) = makeEditor(theme: .turbo)
		let (findBar, control) = nestedBar()
		// The way AppKit does it: the banner carries an appearance of its own.
		findBar.subviews.first?.appearance = NSAppearance(named: .aqua)
		try scroll(scrollView).findBarView = findBar

		XCTAssertEqual(control.appearance?.name, .darkAqua, "the control is what has to be legible")
		XCTAssertEqual(findBar.subviews.first?.appearance?.name, .darkAqua)
	}

	/// Switching themes with the bar already open has to redress it — the bar is built
	/// once and kept.
	func testSwitchingThemeRedressesAnOpenFindBar() throws {
		let (scrollView, textView) = makeEditor(theme: .defaultLightPalette)
		let (findBar, control) = nestedBar()
		try scroll(scrollView).findBarView = findBar

		textView.theme = .turbo
		XCTAssertEqual(findBar.appearance?.name, .darkAqua)
		XCTAssertEqual(control.appearance?.name, .darkAqua)
		XCTAssertEqual(scrollView.scrollerKnobStyle, .light)

		textView.theme = .defaultLightPalette
		XCTAssertEqual(findBar.appearance?.name, .aqua)
		XCTAssertEqual(control.appearance?.name, .aqua)
		XCTAssertEqual(scrollView.scrollerKnobStyle, .dark)
	}

	/// The appearance goes on the find bar alone. On the scroll view or the text view it
	/// would feed back into `effectiveAppearance`, which is what resolves a paired theme —
	/// a dark palette would then keep re-picking the dark half.
	func testTheEditorItselfKeepsTheSystemAppearance() throws {
		let (scrollView, textView) = makeEditor(theme: .turbo)
		try scroll(scrollView).findBarView = NSView()

		XCTAssertNil(scrollView.appearance)
		XCTAssertNil(textView.appearance)
	}

	private func scroll(_ scrollView: NSScrollView) throws -> EditorScrollView {
		try XCTUnwrap(scrollView as? EditorScrollView)
	}

	/// Stands in for what `NSTextFinder` builds: a root, a banner, and a control down
	/// inside it.
	private func nestedBar() -> (root: NSView, control: NSView) {
		let root = NSView()
		let banner = NSView()
		let control = NSView()
		banner.addSubview(control)
		root.addSubview(banner)
		return (root, control)
	}
}
