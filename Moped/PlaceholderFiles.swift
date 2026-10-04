//
//  PlaceholderFiles.swift
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

/// Deletes the empty files `moped` creates for paths that did not exist yet, once they
/// turn out to be unused.
///
/// The sandboxed app may only write where it was handed a file, so it cannot create
/// `moped new.txt` on first save by itself. The script creates the file empty instead —
/// which is what lets ⌘S save straight back to it — and tags it with the extended
/// attribute below. When that document's window closes, or the app quits, a tagged file
/// that is still empty is deleted again, so opening a new name and changing your mind
/// leaves nothing behind.
///
/// The tag rides on the file itself rather than in a list inside this app's container:
/// macOS's app data protection stops the user's shell from writing there without a
/// prompt, and the file is one this app can always read while it is open.
///
/// Both hooks run after any save has happened: the window closes only once the
/// document agreed to, and the unsaved-changes review precedes termination.
@MainActor
final class PlaceholderFiles: NSObject {
	static let shared = PlaceholderFiles()

	/// Must match `PLACEHOLDER_XATTR` in `Resources/moped`.
	private static let attributeName = "net.machorro.roberto.Moped.placeholder"

	private var isObserving = false

	func startObserving() {
		guard !isObserving else {
			return
		}

		isObserving = true

		NotificationCenter.default.addObserver(
			self,
			selector: #selector(windowWillClose(_:)),
			name: NSWindow.willCloseNotification,
			object: nil
		)

		NotificationCenter.default.addObserver(
			self,
			selector: #selector(appWillTerminate(_:)),
			name: NSApplication.willTerminateNotification,
			object: nil
		)
	}

	@objc private func windowWillClose(_ notification: Notification) {
		guard let window = notification.object as? NSWindow,
			let url = (window.windowController?.document as? NSDocument)?.fileURL else {
			return
		}

		discardIfUnused(url)
	}

	@objc private func appWillTerminate(_ notification: Notification) {
		for url in NSDocumentController.shared.documents.compactMap(\.fileURL) {
			discardIfUnused(url)
		}
	}

	/// Deletes `url` if `moped` created it and it is still empty. Once it has content it
	/// is the user's file, so the tag comes off instead and it is never considered again.
	private func discardIfUnused(_ url: URL) {
		let isPlaceholder = url.withUnsafeFileSystemRepresentation { path in
			path.map { getxattr($0, Self.attributeName, nil, 0, 0, 0) >= 0 } ?? false
		}
		guard isPlaceholder else {
			return
		}

		if (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize == 0 {
			try? FileManager.default.removeItem(at: url)
		} else {
			url.withUnsafeFileSystemRepresentation { path in
				if let path {
					_ = removexattr(path, Self.attributeName, 0)
				}
			}
		}
	}
}
