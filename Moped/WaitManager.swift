//
//  WaitManager.swift
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

/// Tracks `moped --wait` sessions and reports completion when the files close.
///
/// Main-actor isolated because every entry point already was: the distributed
/// notification observer and the terminate observer are registered from
/// `applicationWillFinishLaunching`, so they deliver on the main run loop, and the poll
/// timer is scheduled there too. This previously funnelled the same state through a
/// serial queue, which bought nothing and cost a hop on the termination path.
@MainActor
final class WaitManager: NSObject {
	static let shared = WaitManager()
	static func canonicalPath(for url: URL) -> String {
		url.resolvingSymlinksInPath().standardizedFileURL.path
	}

	private enum CLIConstants {
		static let requestNotification = Notification.Name(
			"net.machorro.roberto.Moped.CLIWaitRequest"
		)
		static let completionNotification = Notification.Name(
			"net.machorro.roberto.Moped.CLIWaitComplete"
		)
		static let sessionIDKey = "sessionID"
		static let filesKey = "files"
		static let sessionFileKey = "sessionFilePath"
	}

	private let distributedCenter = DistributedNotificationCenter.default()
	private var sessions: [String: Set<String>] = [:]
	private var sessionFiles: [String: String] = [:]
	private var isObserving = false
	private var pollTimer: Timer?

	func startObserving() {
		guard !isObserving else {
			return
		}

		isObserving = true

		distributedCenter.addObserver(
			self,
			selector: #selector(waitRequestReceived(_:)),
			name: CLIConstants.requestNotification,
			object: nil
		)

		NotificationCenter.default.addObserver(
			self,
			selector: #selector(appWillTerminate(_:)),
			name: NSApplication.willTerminateNotification,
			object: nil
		)
	}

	@objc private func waitRequestReceived(_ notification: Notification) {
		guard let userInfo = notification.userInfo,
			let sessionID = userInfo[CLIConstants.sessionIDKey] as? String,
			let filePaths = userInfo[CLIConstants.filesKey] as? [String] else {
			return
		}

		if let sessionFilePath = userInfo[CLIConstants.sessionFileKey] as? String {
			sessionFiles[sessionID] = sessionFilePath
		}

		let standardizedPaths = Set(filePaths.map {
			WaitManager.canonicalPath(for: URL(fileURLWithPath: $0))
		})
		sessions[sessionID] = standardizedPaths

		if standardizedPaths.isEmpty {
			completeSession(sessionID)
			return
		}

		startPollingIfNeeded()
	}

	private func removePendingPath(_ path: String) {
		let incomingURL = URL(fileURLWithPath: path)
		let incomingCanonical = WaitManager.canonicalPath(for: incomingURL)
		let incomingIdentifier = fileIdentifier(for: incomingURL)
		var finishedSessions: [String] = []

		for (sessionID, paths) in sessions {
			if let matchedPath = paths.first(where: {
				pathsMatch(
					incomingPath: path,
					incomingCanonical: incomingCanonical,
					incomingIdentifier: incomingIdentifier,
					sessionPath: $0
				)
			}) {
				var updatedPaths = paths
				updatedPaths.remove(matchedPath)
				if updatedPaths.isEmpty {
					finishedSessions.append(sessionID)
				} else {
					sessions[sessionID] = updatedPaths
				}
			}
		}

		for sessionID in finishedSessions {
			sessions.removeValue(forKey: sessionID)
			completeSession(sessionID)
		}

		if sessions.isEmpty {
			stopPollingIfNeeded()
		}
	}

	private func pathsMatch(
		incomingPath: String,
		incomingCanonical: String,
		incomingIdentifier: AnyHashable?,
		sessionPath: String
	) -> Bool {
		if incomingPath == sessionPath {
			return true
		}

		let sessionURL = URL(fileURLWithPath: sessionPath)
		if WaitManager.canonicalPath(for: sessionURL) == incomingCanonical {
			return true
		}

		guard let incomingIdentifier = incomingIdentifier,
			let sessionIdentifier = fileIdentifier(for: sessionURL) else {
			return false
		}

		return incomingIdentifier == sessionIdentifier
	}

	private func fileIdentifier(for url: URL) -> AnyHashable? {
		let values = try? url.resourceValues(forKeys: [.fileResourceIdentifierKey])
		if let identifier = values?.fileResourceIdentifier as? NSObject {
			return AnyHashable(identifier)
		}

		return nil
	}

	private func startPollingIfNeeded() {
		guard pollTimer == nil else {
			return
		}

		pollTimer = Timer.scheduledTimer(
			timeInterval: 0.5,
			target: self,
			selector: #selector(pollOpenDocuments),
			userInfo: nil,
			repeats: true
		)
	}

	private func stopPollingIfNeeded() {
		pollTimer?.invalidate()
		pollTimer = nil
	}

	@objc private func pollOpenDocuments() {
		let openPaths: Set<String> = Set(
			NSApplication.shared.windows.compactMap { window in
				guard window.isVisible,
					let url = window.representedURL else {
					return nil
				}

				return WaitManager.canonicalPath(for: url)
			}
		)
		guard !sessions.isEmpty else {
			stopPollingIfNeeded()
			return
		}

		var closedPaths: Set<String> = []
		for paths in sessions.values {
			for path in paths {
				let canonical = WaitManager.canonicalPath(for: URL(fileURLWithPath: path))
				if !openPaths.contains(canonical) {
					closedPaths.insert(path)
				}
			}
		}

		for path in closedPaths {
			removePendingPath(path)
		}
	}

	private func notifyCompletion(for sessionID: String) {
		let userInfo: [String: Any] = [
			CLIConstants.sessionIDKey: sessionID
		]

		distributedCenter.post(
			name: CLIConstants.completionNotification,
			object: nil,
			userInfo: userInfo
		)
	}

	@objc private func appWillTerminate(_ notification: Notification) {
		// Runs inline on purpose. Deferring this to another queue — as it once did —
		// loses the race with process exit, so waiting `moped --wait` clients never see
		// their completion notification and fall back to polling.
		for sessionID in sessions.keys {
			completeSession(sessionID)
		}
		sessions.removeAll()
	}

	private func completeSession(_ sessionID: String) {
		if let sessionFilePath = sessionFiles.removeValue(forKey: sessionID) {
			try? FileManager.default.removeItem(
				at: URL(fileURLWithPath: sessionFilePath)
			)
		}

		notifyCompletion(for: sessionID)
	}
}
