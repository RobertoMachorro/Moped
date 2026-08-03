//
//  LineNumberRulerTests.swift
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

/// The gutter had no coverage at all until a scrolled document turned up numbering that
/// stopped partway down the viewport. Drawing needs a graphics context, so these tests go
/// through `visibleLineNumbers(for:)`, which is the range the draw loop iterates.
final class LineNumberRulerTests: EditorTestCase {
	/// Enough lines to overflow the 400pt test viewport several times over.
	private func longDocument(lines: Int = 200) -> String {
		(1...lines).map { "let line\($0) = \($0)" }.joined(separator: "\n") + "\n"
	}

	private func ruler(of textView: MopedTextView) throws -> LineNumberRulerView {
		try XCTUnwrap(textView.enclosingScrollView?.verticalRulerView as? LineNumberRulerView)
	}

	/// Scrolls the clip view and hands back the rect the ruler reads.
	private func scroll(_ scrollView: NSScrollView, toY offset: CGFloat) -> NSRect {
		scrollView.contentView.setBoundsOrigin(NSPoint(x: scrollView.contentView.bounds.origin.x, y: offset))
		scrollView.reflectScrolledClipView(scrollView.contentView)
		return scrollView.contentView.bounds
	}

	/// The regression: scrolled down, the range must still cover a full viewport of
	/// lines. It used to stop early, because the glyph range was queried without
	/// forcing layout first.
	func testScrolledGutterNumbersTheWholeViewport() throws {
		let (scrollView, textView) = makeEditor()
		textView.setPlainText(longDocument())
		drainHighlightPasses()

		let visible = scroll(scrollView, toY: 1200)
		let range = try ruler(of: textView).visibleLineNumbers(for: visible)

		let lineHeight = try XCTUnwrap(textView.layoutManager?.defaultLineHeight(for: textView.editorFont))
		let expected = Int((visible.height / lineHeight).rounded(.down))

		XCTAssertGreaterThanOrEqual(
			range.count, expected,
			"a \(Int(visible.height))pt viewport fits about \(expected) lines, but the gutter "
				+ "would only number \(range.count) of them"
		)
		XCTAssertGreaterThan(range.lowerBound, 0, "scrolled down, numbering should not start at line 1")
	}

	/// The bug that started this: the gutter drew once at offset zero and was never
	/// invalidated again. The clip view blits its existing pixels on scroll, so the
	/// numbers slid up out of view and the strip revealed at the bottom stayed unpainted
	/// — no numbers, and the bare `NSRulerView` background instead of the theme's.
	/// Scrolling has to change which lines the gutter numbers. It sounds tautological,
	/// but the bug that started this file was the gutter drawing once at offset zero and
	/// never being asked to draw again: the clip view blits its existing pixels, so the
	/// numbers slid up out of view and the strip revealed at the bottom stayed unpainted.
	///
	/// The invalidation itself is not asserted here. `needsDisplay` is serviced
	/// synchronously once the view is in a window, so it reads back false immediately and
	/// would pass whether or not the ruler observes the clip view. That half is verified
	/// by running the app; what this pins down is that the draw path is offset-sensitive,
	/// so a repaint actually produces different output.
	func testScrollingChangesWhichLinesAreNumbered() throws {
		let (scrollView, textView) = makeEditor()
		textView.setPlainText(longDocument())
		drainHighlightPasses()
		let gutter = try ruler(of: textView)

		let atTop = gutter.visibleLineNumbers(for: scrollView.contentView.bounds)
		let scrolled = gutter.visibleLineNumbers(for: scroll(scrollView, toY: 900))

		XCTAssertNotEqual(atTop, scrolled)
		XCTAssertGreaterThan(scrolled.lowerBound, atTop.lowerBound)
	}

	/// The unpainted strip the user actually saw: the gutter must be the theme's colour
	/// over its whole height, bottom included, not just where the numbers reach.
	func testGutterBackgroundCoversItsFullHeight() throws {
		let (scrollView, textView) = makeEditor(theme: .turboPalette)
		let window = NSWindow(
			contentRect: scrollView.frame, styleMask: [.titled],
			backing: .buffered, defer: false
		)
		window.contentView = scrollView
		textView.showsLineNumberGutter = true
		textView.setPlainText(longDocument())
		drainHighlightPasses()
		_ = scroll(scrollView, toY: 900)

		let gutter = try ruler(of: textView)
		let rep = try XCTUnwrap(gutter.bitmapImageRepForCachingDisplay(in: gutter.bounds))
		gutter.cacheDisplay(in: gutter.bounds, to: rep)

		let expected = try XCTUnwrap(MopedTheme.turboPalette.gutterBackground.usingColorSpace(.sRGB))
		let midX = Int(gutter.bounds.width / 2)
		for fraction in [0.05, 0.5, 0.95] {
			let sampleY = Int(gutter.bounds.height * fraction)
			let pixel = try XCTUnwrap(rep.colorAt(x: midX, y: sampleY)?.usingColorSpace(.sRGB))
			XCTAssertEqual(pixel.redComponent, expected.redComponent, accuracy: 0.01, "at \(fraction) down")
			XCTAssertEqual(pixel.greenComponent, expected.greenComponent, accuracy: 0.01, "at \(fraction) down")
			XCTAssertEqual(pixel.blueComponent, expected.blueComponent, accuracy: 0.01, "at \(fraction) down")
		}
	}

	/// The worst case is a viewport whose layout has not been generated yet, which is
	/// exactly what scrolling into fresh territory produces.
	func testGutterNumbersTheWholeViewportWithColdLayout() throws {
		let (scrollView, textView) = makeEditor()
		textView.setPlainText(longDocument())
		// Deliberately no drainHighlightPasses(): leave layout as cold as possible.

		let visible = scroll(scrollView, toY: 2000)
		let range = try ruler(of: textView).visibleLineNumbers(for: visible)

		let lineHeight = try XCTUnwrap(textView.layoutManager?.defaultLineHeight(for: textView.editorFont))
		let expected = Int((visible.height / lineHeight).rounded(.down))

		XCTAssertGreaterThanOrEqual(
			range.count, expected,
			"cold layout still has to number the whole viewport, not just the laid-out part"
		)
	}

	func testUnscrolledGutterStartsAtTheFirstLine() throws {
		let (scrollView, textView) = makeEditor()
		textView.setPlainText(longDocument())
		drainHighlightPasses()

		let range = try ruler(of: textView).visibleLineNumbers(for: scrollView.contentView.bounds)
		XCTAssertEqual(range.lowerBound, 0)
	}

	/// A document shorter than the viewport must number every line and stop, rather than
	/// running past the end of the offset array.
	func testShortDocumentNumbersEveryLineAndNoMore() throws {
		let (scrollView, textView) = makeEditor()
		textView.setPlainText("one\ntwo\nthree\n")
		drainHighlightPasses()

		let range = try ruler(of: textView).visibleLineNumbers(for: scrollView.contentView.bounds)
		XCTAssertEqual(range.lowerBound, 0)
		XCTAssertLessThanOrEqual(range.upperBound, try ruler(of: textView).knownLineCount)
	}

	// MARK: - Thickness

	/// `ruleThickness` used to be assigned from inside the draw path, which re-tiles the
	/// scroll view while it is drawing. Measuring the gutter is fine; resizing it there
	/// is not.
	func testDrawingDoesNotChangeRuleThickness() throws {
		let (scrollView, textView) = makeEditor()
		// A one-digit document, so the thickness this *wants* (28) is far from the 40 it
		// starts at — a document whose measured width lands near 40 would pass this test
		// without exercising anything.
		textView.setPlainText(longDocument(lines: 5))

		let gutter = try ruler(of: textView)
		let before = gutter.ruleThickness
		_ = gutter.visibleLineNumbers(for: scrollView.contentView.bounds)
		XCTAssertEqual(
			gutter.ruleThickness, before, accuracy: 0.001,
			"measuring the gutter during a draw is fine; resizing it there re-tiles the "
				+ "scroll view underneath the draw"
		)
	}

	/// The gutter still has to widen for a document whose line count needs more digits —
	/// just on a later runloop turn rather than mid-draw, which is what the drain is for.
	func testGutterWidensForMoreDigits() throws {
		let (scrollView, textView) = makeEditor()
		let gutter = try ruler(of: textView)

		textView.setPlainText(longDocument(lines: 5))
		_ = gutter.visibleLineNumbers(for: scrollView.contentView.bounds)
		drainHighlightPasses()
		let narrow = gutter.ruleThickness

		textView.setPlainText(longDocument(lines: 12_000))
		_ = gutter.visibleLineNumbers(for: scrollView.contentView.bounds)
		drainHighlightPasses()
		let wide = gutter.ruleThickness

		XCTAssertGreaterThan(wide, narrow, "five digits needs a wider gutter than one")
	}

	// MARK: - Line counting

	/// `LineIndex.lineStarts` stops at the last newline rather than opening a start
	/// beyond it, so a file ending in `\n` numbers only its content lines.
	func testKnownLineCountTracksEdits() throws {
		let (_, textView) = makeEditor()
		textView.setPlainText("one\ntwo\n")
		let gutter = try ruler(of: textView)
		XCTAssertEqual(gutter.knownLineCount, 2)

		textView.setPlainText(longDocument(lines: 40))
		XCTAssertEqual(gutter.knownLineCount, 40)

		textView.setPlainText("no trailing newline")
		XCTAssertEqual(gutter.knownLineCount, 1)
	}
}
