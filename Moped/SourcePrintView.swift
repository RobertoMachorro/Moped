//
//  SourcePrintView.swift
//
//  Moped - A general purpose text editor, small and light.
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

import AppKit
import CoreText

final class SourcePrintView: NSView {
	private let framesetter: CTFramesetter
	private let textLength: Int
	/// Recomputed in `knowsPageRange`, not fixed at init — see there for why.
	private var pageRanges: [CFRange]
	private var printableSize: NSSize

	override var isFlipped: Bool {
		true
	}

	init(content: String, printInfo: NSPrintInfo, font: NSFont) {
		printableSize = SourcePrintView.printableSize(for: printInfo)

		let paragraphStyle = NSMutableParagraphStyle()
		paragraphStyle.lineBreakMode = .byCharWrapping
		paragraphStyle.alignment = .left

		let attributes: [NSAttributedString.Key: Any] = [
			.font: font,
			.foregroundColor: NSColor.textColor,
			.paragraphStyle: paragraphStyle
		]
		let attributed = NSAttributedString(string: content, attributes: attributes)
		framesetter = CTFramesetterCreateWithAttributedString(attributed as CFAttributedString)
		textLength = attributed.length

		pageRanges = SourcePrintView.paginate(
			framesetter: framesetter,
			textLength: attributed.length,
			printableSize: printableSize
		)

		let pageCount = max(pageRanges.count, 1)
		super.init(frame: NSRect(
			x: 0, y: 0,
			width: printableSize.width,
			height: CGFloat(pageCount) * printableSize.height
		))
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	/// Paper size, orientation, margins and scale are all still editable in the print panel,
	/// which opens *after* `init`. Paginating only at init meant choosing Landscape or A4
	/// laid the text out for the old page and clipped it. This is the first thing the print
	/// operation asks the view, and by then `NSPrintOperation.current` carries the settings
	/// the user actually confirmed, so the layout is redone against those.
	override func knowsPageRange(_ range: NSRangePointer) -> Bool {
		if let live = NSPrintOperation.current?.printInfo {
			let updated = SourcePrintView.printableSize(for: live)
			if updated != printableSize {
				printableSize = updated
				pageRanges = SourcePrintView.paginate(
					framesetter: framesetter,
					textLength: textLength,
					printableSize: updated
				)
				setFrameSize(NSSize(
					width: updated.width,
					height: CGFloat(max(pageRanges.count, 1)) * updated.height
				))
			}
		}
		range.pointee = NSRange(location: 1, length: max(pageRanges.count, 1))
		return true
	}

	/// The area text may occupy, in the view's own coordinates. Dividing by the scaling
	/// factor is what keeps a scaled page holding proportionally more text rather than
	/// cropping: AppKit scales the view when imaging it, so at 50% the view has to be twice
	/// the paper's size to cover it.
	private static func printableSize(for printInfo: NSPrintInfo) -> NSSize {
		let scale = printInfo.scalingFactor > 0 ? printInfo.scalingFactor : 1
		let width = printInfo.paperSize.width - printInfo.leftMargin - printInfo.rightMargin
		let height = printInfo.paperSize.height - printInfo.topMargin - printInfo.bottomMargin
		return NSSize(width: max(1, width / scale), height: max(1, height / scale))
	}

	override func rectForPage(_ page: Int) -> NSRect {
		let clampedPage = max(1, page)
		return NSRect(
			x: 0,
			y: CGFloat(clampedPage - 1) * printableSize.height,
			width: printableSize.width,
			height: printableSize.height
		)
	}

	override func draw(_ dirtyRect: NSRect) {
		guard let context = NSGraphicsContext.current?.cgContext else {
			return
		}

		let pageIndex = max(
			0,
			min(
				Int(floor(dirtyRect.minY / printableSize.height)),
				max(pageRanges.count - 1, 0)
			)
		)
		guard pageRanges.indices.contains(pageIndex) else {
			return
		}

		let pageRect = rectForPage(pageIndex + 1)
		let path = CGPath(
			rect: CGRect(x: 0, y: 0, width: printableSize.width, height: printableSize.height),
			transform: nil
		)
		let frame = CTFramesetterCreateFrame(framesetter, pageRanges[pageIndex], path, nil)

		context.saveGState()
		context.translateBy(x: 0, y: pageRect.minY + printableSize.height)
		context.scaleBy(x: 1, y: -1)
		CTFrameDraw(frame, context)
		context.restoreGState()
	}

	private static func paginate(framesetter: CTFramesetter, textLength: Int, printableSize: NSSize) -> [CFRange] {
		let path = CGPath(
			rect: CGRect(x: 0, y: 0, width: printableSize.width, height: printableSize.height),
			transform: nil
		)

		var ranges: [CFRange] = []
		var location = 0
		while location < textLength {
			let frame = CTFramesetterCreateFrame(
				framesetter,
				CFRange(location: location, length: 0),
				path,
				nil
			)
			let visible = CTFrameGetVisibleStringRange(frame)
			guard visible.length > 0 else {
				break
			}
			ranges.append(visible)
			location += visible.length
		}

		if ranges.isEmpty {
			ranges.append(CFRange(location: 0, length: 0))
		}
		return ranges
	}
}
