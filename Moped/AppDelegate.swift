//
//  AppDelegate.swift
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

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	// MARK: - Application Delegate

	func applicationDidFinishLaunching(_ aNotification: Notification) {
		// Insert code here to initialize your application
	}

	func applicationWillFinishLaunching(_ notification: Notification) {
		WaitManager.shared.startObserving()
	}

	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}

	func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
		.terminateNow
	}

}

extension AppDelegate {
	// MARK: - Help Menu Actions

	@IBAction func linkToLicense(_ sender: Any) {
		showWebsite(using: "https://www.gnu.org/licenses/gpl-3.0.html")
	}

	@IBAction func linkToSources(_ sender: Any) {
		showWebsite(using: "https://github.com/RobertoMachorro/Moped")
	}

	@IBAction func linkToIssues(_ sender: Any) {
		showWebsite(using: "https://github.com/RobertoMachorro/Moped/issues")
	}

	@IBAction func linkToIconSite(_ sender: Any) {
		showWebsite(using: "https://all-free-download.com/free-vector/download/scooter-icons-collection-classical-colored-sketch_6832617.html")
	}

	func showWebsite(using address: String) {
		if let url = URL(string: address) {
			NSWorkspace.shared.open(url)
		}
	}
}

extension AppDelegate {
	// MARK: - Moped CLI

	@IBAction func setupMopedCLI(_ sender: Any) {
		guard let cliURL = Bundle.main.url(forResource: "moped", withExtension: nil) else {
			showCLIAlert(
				title: "moped CLI not found.",
				message: "Reinstall Moped to restore the embedded CLI tool."
			)
			return
		}

		let targetURL = URL(fileURLWithPath: "/usr/local/bin/moped")

		do {
			let alreadyInstalled = try installCLI(from: cliURL, to: targetURL)
			let message = alreadyInstalled
				? "moped is already installed at /usr/local/bin/moped."
				: "moped is now available at /usr/local/bin/moped."
			showCLIAlert(title: "Setup Complete", message: message)
		} catch {
			showCLIAlert(
				title: "Unable to install moped.",
				message: "Try running: sudo ln -sf \"\(cliURL.path)\" \"\(targetURL.path)\""
			)
		}
	}

	private func installCLI(from sourceURL: URL, to targetURL: URL) throws -> Bool {
		let fileManager = FileManager.default
		let targetDirectory = targetURL.deletingLastPathComponent()

		try fileManager.createDirectory(
			at: targetDirectory,
			withIntermediateDirectories: true,
			attributes: nil
		)

		if fileManager.fileExists(atPath: targetURL.path) {
			if let destination = try? fileManager.destinationOfSymbolicLink(atPath: targetURL.path) {
				let resolvedDestination = URL(fileURLWithPath: destination, relativeTo: targetDirectory)
					.standardizedFileURL
				if resolvedDestination == sourceURL.standardizedFileURL {
					return true
				}
			}

			try fileManager.removeItem(at: targetURL)
		}

		try fileManager.createSymbolicLink(at: targetURL, withDestinationURL: sourceURL)
		return false
	}

	private func showCLIAlert(title: String, message: String) {
		let alert = NSAlert()
		alert.messageText = title
		alert.informativeText = message
		alert.runModal()
	}
}

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
	private let stateQueue = DispatchQueue(label: "net.machorro.roberto.Moped.WaitManager.state")

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

	func handleDocumentClosePath(_ path: String) {
		stateQueue.async { [weak self] in
			self?.removePendingPathLocked(path)
		}
	}

	@objc private func waitRequestReceived(_ notification: Notification) {
		guard let userInfo = notification.userInfo,
			let sessionID = userInfo[CLIConstants.sessionIDKey] as? String,
			let filePaths = userInfo[CLIConstants.filesKey] as? [String] else {
			return
		}

		stateQueue.async { [weak self] in
			guard let self = self else {
				return
			}

			if let sessionFilePath = userInfo[CLIConstants.sessionFileKey] as? String {
				self.sessionFiles[sessionID] = sessionFilePath
			}

			let standardizedPaths = Set(filePaths.map {
				WaitManager.canonicalPath(for: URL(fileURLWithPath: $0))
			})
			self.sessions[sessionID] = standardizedPaths

			if standardizedPaths.isEmpty {
				self.completeSessionLocked(sessionID)
				return
			}

			DispatchQueue.main.async { [weak self] in
				self?.startPollingIfNeeded()
			}
		}
	}

	private func removePendingPathLocked(_ path: String) {
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
			completeSessionLocked(sessionID)
		}

		if sessions.isEmpty {
			DispatchQueue.main.async { [weak self] in
				self?.stopPollingIfNeeded()
			}
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
		var shouldStopPolling = false
		let closedPaths: [String] = stateQueue.sync {
			guard !sessions.isEmpty else {
				shouldStopPolling = true
				return []
			}

			var collectedPaths: [String] = []
			for paths in sessions.values {
				for path in paths {
					let canonical = WaitManager.canonicalPath(for: URL(fileURLWithPath: path))
					if !openPaths.contains(canonical) {
						collectedPaths.append(path)
					}
				}
			}

			return collectedPaths
		}

		if shouldStopPolling {
			stopPollingIfNeeded()
			return
		}

		if !closedPaths.isEmpty {
			stateQueue.async { [weak self] in
				guard let self = self else {
					return
				}

				for path in Set(closedPaths) {
					self.removePendingPathLocked(path)
				}
			}
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
		stateQueue.async { [weak self] in
			guard let self = self else {
				return
			}

			for sessionID in self.sessions.keys {
				self.completeSessionLocked(sessionID)
			}
			self.sessions.removeAll()
		}
	}

	private func completeSessionLocked(_ sessionID: String) {
		if let sessionFilePath = sessionFiles.removeValue(forKey: sessionID) {
			try? FileManager.default.removeItem(
				at: URL(fileURLWithPath: sessionFilePath)
			)
		}

		notifyCompletion(for: sessionID)
	}
}
