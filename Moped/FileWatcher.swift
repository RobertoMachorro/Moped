//
//  FileWatcher.swift
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

import Foundation

final class FileWatcher {
	private var source: DispatchSourceFileSystemObject?
	private var watchedURL: URL?
	private var changeHandler: (() -> Void)?

	func start(url: URL, onChange: @escaping () -> Void) {
		stop()
		watchedURL = url
		changeHandler = onChange
		startSource(for: url)
	}

	func stop() {
		source?.cancel()
		source = nil
		watchedURL = nil
		changeHandler = nil
	}

	deinit { stop() }

	// Many editors save by writing a temp file then renaming it over the original,
	// which replaces the inode our fd points at. `.write` never fires in that case,
	// so we also listen for `.delete`/`.rename` and re-open the path to track the new inode.
	private func startSource(for url: URL) {
		// Security-scoped access is needed in sandboxed builds to open a file descriptor
		// even with O_EVTONLY. The scope can be released once the fd is open.
		let didStartAccess = url.startAccessingSecurityScopedResource()
		let openedFd = open(url.path, O_EVTONLY)
		if didStartAccess { url.stopAccessingSecurityScopedResource() }
		guard openedFd != -1 else { return }
		let src = DispatchSource.makeFileSystemObjectSource(
			fileDescriptor: openedFd,
			eventMask: [.write, .extend, .delete, .rename],
			queue: .main)
		src.setEventHandler { [weak self] in
			guard let self, let current = self.source else { return }
			let events = current.data
			self.changeHandler?()
			if events.contains(.delete) || events.contains(.rename) {
				self.rewatch()
			}
		}
		src.setCancelHandler {
			close(openedFd)
		}
		source = src
		src.resume()
	}

	private func rewatch() {
		guard watchedURL != nil else { return }
		source?.cancel()
		source = nil
		// Brief delay lets the rename complete and the new file settle before we re-open.
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
			guard let self, let url = self.watchedURL else { return }
			self.startSource(for: url)
		}
	}
}
