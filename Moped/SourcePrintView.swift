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
	private let pageRanges: [CFRange]
	private let printableSize: NSSize

	override var isFlipped: Bool {
		true
	}

	init(content: String, printInfo: NSPrintInfo) {
		let printableWidth = max(1, printInfo.paperSize.width - printInfo.leftMargin - printInfo.rightMargin)
		let printableHeight = max(1, printInfo.paperSize.height - printInfo.topMargin - printInfo.bottomMargin)
		printableSize = NSSize(width: printableWidth, height: printableHeight)

		let font = NSFont.userFixedPitchFont(ofSize: NSFont.systemFontSize)
			?? NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
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

		pageRanges = SourcePrintView.paginate(
			framesetter: framesetter,
			textLength: attributed.length,
			printableSize: printableSize
		)

		let pageCount = max(pageRanges.count, 1)
		let totalHeight = CGFloat(pageCount) * printableHeight
		super.init(frame: NSRect(x: 0, y: 0, width: printableWidth, height: totalHeight))
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func knowsPageRange(_ range: NSRangePointer) -> Bool {
		range.pointee = NSRange(location: 1, length: max(pageRanges.count, 1))
		return true
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
