//
//  EditorScrollView.swift
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

/// The editor's scroll view. Exists for one reason: the find bar sits inside the scroll
/// view, drawn over the editor's own background colour, and its controls have to stay
/// legible against whatever the theme paints there.
///
/// `NSScrollView` already conforms to `NSTextFinderBarContainer`, so `findBarView` is
/// where `NSTextFinder` hands over the bar it built — the one moment the view exists to
/// be dressed.
final class EditorScrollView: NSScrollView {
	/// Appearance forced on the find bar. Applied on assignment and again whenever the
	/// bar is created or shown, so a theme switch reaches a bar that is already open.
	///
	/// Deliberately *not* set on this view or the text view. `MopedTextView` derives its
	/// resolved palette from `effectiveAppearance`, so an appearance chosen from the
	/// palette's own background and applied to an ancestor of the text view is a loop: a
	/// paired theme would flip to its other half. The find bar is a sibling of the clip
	/// view, which is what makes dressing it there safe.
	var findBarAppearance: NSAppearance? {
		didSet { applyFindBarAppearance() }
	}

	override var findBarView: NSView? {
		get { super.findBarView }
		set {
			super.findBarView = newValue
			applyFindBarAppearance()
		}
	}

	override var isFindBarVisible: Bool {
		get { super.isFindBarVisible }
		set {
			super.isFindBarVisible = newValue
			applyFindBarAppearance()
		}
	}

	/// Sets the appearance on every view in the bar, not only its root.
	///
	/// The root alone is not enough: AppKit pins an explicit appearance on the bar's inner
	/// banner, so nothing set above it reaches the search field, the ‹ › control, Done or
	/// the replace row. Dumping the live hierarchy shows exactly that — the root reading
	/// `darkAqua` while every child still reads `aqua`. Hence the walk.
	private func applyFindBarAppearance() {
		guard let bar = super.findBarView else {
			return
		}
		Self.apply(findBarAppearance, to: bar)
	}

	private static func apply(_ appearance: NSAppearance?, to view: NSView) {
		view.appearance = appearance
		for subview in view.subviews {
			apply(appearance, to: subview)
		}
	}
}
