//
//  WindowController.swift
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

import Cocoa

class WindowController: NSWindowController {
	override func windowDidLoad() {
		super.windowDidLoad()

		NotificationCenter.default.addObserver(
			self,
			selector: #selector(windowWillClose(_:)),
			name: NSWindow.willCloseNotification,
			object: window
		)
	}

	required init?(coder: NSCoder) {
		super.init(coder: coder)
		shouldCascadeWindows = true
	}

	deinit {
		NotificationCenter.default.removeObserver(self)
	}

	@objc private func windowWillClose(_ notification: Notification) {
		guard let document = document as? NSDocument else {
			return
		}

		let path = (document as? Document)?.waitTrackingPath()
			?? document.fileURL.map { WaitManager.canonicalPath(for: $0) }
		guard let path = path else {
			return
		}

		WaitManager.shared.handleDocumentClosePath(path)
	}
}
