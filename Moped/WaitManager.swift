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
		static let sessionIDKey = "sessionID"
		static let filesKey = "files"
		static let sessionFileKey = "sessionFilePath"
	}

	/// How long a requested path may stay unopened before the session is released anyway.
	/// Long enough for a cold launch with a multi-megabyte file, short enough that an open
	/// that failed outright does not hold the caller's terminal open indefinitely.
	private static let openGracePeriod: TimeInterval = 10

	private let distributedCenter = DistributedNotificationCenter.default()
	private var sessions: [String: Set<String>] = [:]
	private var sessionFiles: [String: String] = [:]
	/// When each session's request arrived, for the grace period above.
	private var sessionStarts: [String: Date] = [:]
	/// Canonical paths this manager has actually observed open. A path is only treated as
	/// closed once it appears here, which is what distinguishes "closed" from "not open yet".
	private var seenOpenPaths: Set<String> = []
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
		sessionStarts[sessionID] = Date()

		if standardizedPaths.isEmpty {
			sessions.removeValue(forKey: sessionID)
			sessionStarts.removeValue(forKey: sessionID)
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
			sessionStarts.removeValue(forKey: sessionID)
			completeSession(sessionID)
		}

		// Keep `seenOpenPaths` to the paths still being waited on, so a long-running app
		// does not accumulate one entry per file ever opened through the CLI.
		let stillPending = Set(sessions.values.flatMap { $0 }.map {
			WaitManager.canonicalPath(for: URL(fileURLWithPath: $0))
		})
		seenOpenPaths.formIntersection(stillPending)

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
		// Ask the document controller rather than inspecting windows. Window
		// visibility answers a different question than "is this document still
		// open": a miniaturized window, and every window of a hidden app, reports
		// `isVisible == false` while its document is very much open, which ended
		// the session early. Testing `representedURL` on any window regardless of
		// visibility trades that for the worse failure — a window ordered out on
		// close can outlive the document in `NSApp.windows`, and a session that
		// never completes hangs the caller instead of returning too soon.
		//
		// `NSDocumentController` is authoritative for open documents, drops them
		// on close, and is what `AppDelegate` already trusts to save the session.
		// It also populates earlier than windows do — a document is registered
		// before its window controller exists — so the open-side race the script's
		// startup delay covers gets no worse.
		let openPaths: Set<String> = Set(
			NSDocumentController.shared.documents.compactMap { document in
				document.fileURL.map(WaitManager.canonicalPath(for:))
			}
		)
		guard !sessions.isEmpty else {
			stopPollingIfNeeded()
			return
		}

		var closedPaths: Set<String> = []
		for (sessionID, paths) in sessions {
			let expired = sessionStarts[sessionID].map {
				Date().timeIntervalSince($0) > WaitManager.openGracePeriod
			} ?? true

			for path in paths {
				let canonical = WaitManager.canonicalPath(for: URL(fileURLWithPath: path))
				if openPaths.contains(canonical) {
					seenOpenPaths.insert(canonical)
					continue
				}
				// Absent from the document controller means "closed" only once the path has
				// actually been seen open. Otherwise a cold launch slower than the first poll
				// completed the session before the document ever registered — as
				// `git core.editor`, that returned an empty commit message.
				//
				// A path that never shows up is given `openGracePeriod` and then released
				// anyway: if the open failed outright, hanging the caller's terminal forever
				// is the worse of the two failures.
				if seenOpenPaths.contains(canonical) || expired {
					closedPaths.insert(path)
				}
			}
		}

		for path in closedPaths {
			removePendingPath(path)
		}
	}

	@objc private func appWillTerminate(_ notification: Notification) {
		// Runs inline on purpose. Deferring this to another queue — as it once did — loses
		// the race with process exit, and deleting the session file is the only thing that
		// releases a waiting `moped --wait`.
		for sessionID in sessions.keys {
			completeSession(sessionID)
		}
		sessions.removeAll()
		sessionStarts.removeAll()
		seenOpenPaths.removeAll()
		stopPollingIfNeeded()
	}

	/// Deleting the session file *is* the completion signal — `Resources/moped` polls for
	/// the file's disappearance. There is deliberately no notification to go with it: the
	/// script never listened for one, and a sandboxed app's distributed-notification
	/// `userInfo` is dropped in transit anyway, so a listener would learn nothing.
	private func completeSession(_ sessionID: String) {
		if let sessionFilePath = sessionFiles.removeValue(forKey: sessionID) {
			try? FileManager.default.removeItem(
				at: URL(fileURLWithPath: sessionFilePath)
			)
		}
	}
}
