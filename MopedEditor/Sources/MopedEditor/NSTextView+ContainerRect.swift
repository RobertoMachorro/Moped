//
//  NSTextView+ContainerRect.swift
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

import AppKit

extension NSTextView {
	/// A rect in this view's coordinates, translated into its text container's. The
	/// container sits at `textContainerOrigin` (the inset, on both axes), so every query
	/// about which glyphs a view rect holds has to translate it, or it asks about a band
	/// 4pt off from the one drawn there.
	func containerRect(forViewRect rect: NSRect) -> NSRect {
		rect.offsetBy(dx: -textContainerOrigin.x, dy: -textContainerOrigin.y)
	}
}
