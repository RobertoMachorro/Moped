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

class AppDelegate: NSObject, NSApplicationDelegate {
	private var preferencesObserver: NSObjectProtocol?

	// MARK: - Application Delegate

	func applicationDidFinishLaunching(_ aNotification: Notification) {
		NSApp.setActivationPolicy(.regular)
		NSApp.activate(ignoringOtherApps: true)
		applySelectedAppIcon()
		startObservingPreferenceChanges()

		// Skip launch behavior if documents were already opened externally
		// (e.g., via Finder double-click or `moped <file>` from the CLI).
		guard NSDocumentController.shared.documents.isEmpty else { return }

		let prefs = Preferences.userShared
		if prefs.reopenPreviousOnLaunch {
			reopenPreviousDocuments()
		} else if prefs.openEmptyOnLaunch {
			NSDocumentController.shared.newDocument(nil)
		}
	}

	func applicationWillFinishLaunching(_ notification: Notification) {
		WaitManager.shared.startObserving()
	}

	func applicationWillTerminate(_ aNotification: Notification) {
		savePreviousDocuments()
	}

	func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
		.terminateNow
	}

	func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
		true
	}

	deinit {
		if let preferencesObserver {
			NotificationCenter.default.removeObserver(preferencesObserver)
		}
	}

	private func startObservingPreferenceChanges() {
		preferencesObserver = NotificationCenter.default.addObserver(
			forName: Notification.Name(rawValue: "PreferencesChanged"),
			object: nil,
			queue: .main
		) { [weak self] _ in
			self?.applySelectedAppIcon()
		}
	}

	private func savePreviousDocuments() {
		let entries: [RestoredDocument] = NSDocumentController.shared.documents.compactMap { document in
			guard let url = document.fileURL,
				  let bookmark = try? url.bookmarkData(
					options: .withSecurityScope,
					includingResourceValuesForKeys: nil,
					relativeTo: nil
				  ) else { return nil }

			let window = document.windowControllers.first?.window
				?? NSApp.windows.first(where: { $0.windowController?.document as AnyObject === document })
			let frameString = window.map { NSStringFromRect($0.frame) }

			return RestoredDocument(bookmark: bookmark, frame: frameString)
		}
		Preferences.userShared.lastOpenDocuments = entries
	}

	private func reopenPreviousDocuments() {
		let entries = Preferences.userShared.lastOpenDocuments
		var refreshedEntries: [RestoredDocument] = []
		var refreshedAny = false

		for entry in entries {
			var isStale = false
			guard let url = try? URL(
				resolvingBookmarkData: entry.bookmark,
				options: .withSecurityScope,
				relativeTo: nil,
				bookmarkDataIsStale: &isStale
			) else { continue }

			let didStart = url.startAccessingSecurityScopedResource()

			if isStale,
			   let refreshed = try? url.bookmarkData(
				options: .withSecurityScope,
				includingResourceValuesForKeys: nil,
				relativeTo: nil
			   ) {
				refreshedEntries.append(RestoredDocument(bookmark: refreshed, frame: entry.frame))
				refreshedAny = true
			} else {
				refreshedEntries.append(entry)
			}

			let savedFrame = entry.frame.map { NSRectFromString($0) }
			NSDocumentController.shared.openDocument(
				withContentsOf: url,
				display: true
			) { [weak self] document, _, _ in
				if didStart {
					url.stopAccessingSecurityScopedResource()
				}
				if let document, let frame = savedFrame, !NSEqualRects(frame, .zero) {
					self?.applyFrame(frame, to: document, retriesLeft: 5)
				}
			}
		}

		if refreshedAny {
			Preferences.userShared.lastOpenDocuments = refreshedEntries
		}
	}

	private func applyFrame(_ rect: NSRect, to document: NSDocument, retriesLeft: Int) {
		if let window = document.windowControllers.first?.window
			?? NSApp.windows.first(where: { $0.windowController?.document as AnyObject === document }) {
			window.setFrame(rect, display: true)
			return
		}
		guard retriesLeft > 0 else { return }
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
			self?.applyFrame(rect, to: document, retriesLeft: retriesLeft - 1)
		}
	}

	private func applySelectedAppIcon() {
		let selectedIcon = Preferences.userShared.selectedAppIcon
		if let iconImage = NSImage(named: selectedIcon.appIconSetName) {
			NSApplication.shared.applicationIconImage = iconImage
		} else if
			let iconFilePath = Bundle.main.path(
				forResource: selectedIcon.appIconSetName,
				ofType: "icns"
			),
			let iconImage = NSImage(contentsOfFile: iconFilePath) {
			NSApplication.shared.applicationIconImage = iconImage
		} else {
			NSApplication.shared.applicationIconImage = NSImage(named: "AppIcon")
		}
	}
}

extension AppDelegate {
	// MARK: - Windows

	@IBAction func showAboutWindow(_ sender: Any?) {
		AppActions.shared.showAboutWindow()
	}
}

extension AppDelegate {
	// MARK: - Help Menu Actions

	@IBAction func linkToLicense(_ sender: Any) {
		AppActions.shared.linkToLicense()
	}

	@IBAction func linkToSources(_ sender: Any) {
		AppActions.shared.linkToSources()
	}

	@IBAction func linkToIssues(_ sender: Any) {
		AppActions.shared.linkToIssues()
	}

	@IBAction func linkToIconSite(_ sender: Any) {
		AppActions.shared.linkToIconSite()
	}
}

extension AppDelegate {
	// MARK: - Moped CLI

	@IBAction func setupMopedCLI(_ sender: Any) {
		AppActions.shared.setupMopedCLI()
	}
}
