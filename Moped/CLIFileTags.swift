//
//  CLIFileTags.swift
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

/// Answers the extended attributes `Resources/moped` puts on the files it hands over.
///
/// The files are the only channel the script and this sandboxed app share. macOS's app data
/// protection stops the user's shell from writing into this app's container — which is
/// where `moped --wait` used to leave a session file, and why it failed with "Operation not
/// permitted" — while the app can always write to a document it has open.
///
/// - `placeholder`: the script created the file because it did not exist yet; the app could
///   not create it on first save by itself, since it may only write where it was handed a
///   file. If it is still empty when its window closes, or the app quits, it is deleted
///   again, so opening a new name and changing your mind leaves nothing behind.
/// - `wait.<uuid>`: `moped --wait` polls until this is gone, one per invocation so waits on
///   the same file stay independent. The script sets it to `pending`, this type changes it
///   to `open` once the document is on screen, and removes it when the window closes or the
///   app quits. One still `pending` after a few seconds tells the script the open failed,
///   so it stops waiting rather than hang the caller's terminal.
///
/// "On screen" is reported twice: when a document first shows its file (`MopedApp`), and
/// whenever an open document's attributes change (`MopedDocument`'s file watcher). The
/// second is the only sign of `moped --wait` on a file that is already open — `open` then
/// just brings its window forward, which posts nothing if it was already the key window.
///
/// The closing hooks run after any save has happened: the window closes only once the
/// document agreed to, and the unsaved-changes review precedes termination.
@MainActor
final class CLIFileTags: NSObject {
	static let shared = CLIFileTags()

	/// Each must match its counterpart in `Resources/moped`.
	private static let placeholderAttribute = "net.machorro.roberto.Moped.placeholder"
	private static let waitAttributePrefix = "net.machorro.roberto.Moped.wait."

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

	/// Tells each waiting `moped --wait` that the file at `url` is on screen.
	func documentShown(_ url: URL) {
		for name in Self.waitAttributes(at: url) where Self.value(of: name, at: url) == "pending" {
			Self.setValue("open", of: name, at: url)
		}
	}

	@objc private func windowWillClose(_ notification: Notification) {
		guard let window = notification.object as? NSWindow,
			let url = (window.windowController?.document as? NSDocument)?.fileURL else {
			return
		}

		documentClosed(url)
	}

	@objc private func appWillTerminate(_ notification: Notification) {
		for url in NSDocumentController.shared.documents.compactMap(\.fileURL) {
			documentClosed(url)
		}
	}

	/// Releases every `moped --wait` on `url`, and deletes the file if `moped` created it and
	/// it is still empty. Once it has content it is the user's file, so the placeholder tag
	/// comes off instead and it is never considered again. Also called for the URL a document
	/// leaves on Save As.
	func documentClosed(_ url: URL) {
		for name in Self.waitAttributes(at: url) {
			Self.removeValue(of: name, at: url)
		}

		guard Self.value(of: Self.placeholderAttribute, at: url) != nil else {
			return
		}

		if (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize == 0 {
			try? FileManager.default.removeItem(at: url)
		} else {
			Self.removeValue(of: Self.placeholderAttribute, at: url)
		}
	}

	private static func waitAttributes(at url: URL) -> [String] {
		url.withUnsafeFileSystemRepresentation { path -> [String] in
			guard let path else {
				return []
			}
			let length = listxattr(path, nil, 0, 0)
			guard length > 0 else {
				return []
			}
			var names = [CChar](repeating: 0, count: length)
			guard listxattr(path, &names, length, 0) == length else {
				return []
			}
			// A run of NUL-terminated names.
			return names.split(separator: 0)
				.compactMap { String(bytes: $0.map(UInt8.init(bitPattern:)), encoding: .utf8) }
				.filter { $0.hasPrefix(waitAttributePrefix) }
		}
	}

	private static func value(of name: String, at url: URL) -> String? {
		url.withUnsafeFileSystemRepresentation { path -> String? in
			guard let path else {
				return nil
			}
			let length = getxattr(path, name, nil, 0, 0, 0)
			guard length >= 0 else {
				return nil
			}
			var bytes = [UInt8](repeating: 0, count: length)
			guard getxattr(path, name, &bytes, length, 0, 0) == length else {
				return nil
			}
			return String(bytes: bytes, encoding: .utf8)
		}
	}

	private static func setValue(_ value: String, of name: String, at url: URL) {
		let bytes = Array(value.utf8)
		url.withUnsafeFileSystemRepresentation { path in
			if let path {
				_ = setxattr(path, name, bytes, bytes.count, 0, 0)
			}
		}
	}

	private static func removeValue(of name: String, at url: URL) {
		url.withUnsafeFileSystemRepresentation { path in
			if let path {
				_ = removexattr(path, name, 0)
			}
		}
	}
}
