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
	private var fileDescriptor: Int32 = -1

	func start(url: URL, onChange: @escaping () -> Void) {
		stop()
		// Security-scoped access is needed in sandboxed builds to open a file descriptor
		// even with O_EVTONLY. The scope can be released once the fd is open.
		let didStartAccess = url.startAccessingSecurityScopedResource()
		let openedFd = open(url.path, O_EVTONLY)
		if didStartAccess { url.stopAccessingSecurityScopedResource() }
		guard openedFd != -1 else { return }
		fileDescriptor = openedFd
		let src = DispatchSource.makeFileSystemObjectSource(
			fileDescriptor: openedFd, eventMask: .write, queue: .main)
		src.setEventHandler(handler: onChange)
		src.setCancelHandler { [weak self] in
			guard let self, self.fileDescriptor != -1 else { return }
			close(self.fileDescriptor)
			self.fileDescriptor = -1
		}
		src.resume()
		source = src
	}

	func stop() {
		source?.cancel()
		source = nil
	}

	deinit { stop() }
}
