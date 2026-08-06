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

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
	/// `nonisolated(unsafe)` so the nonisolated `deinit` can unregister it. The token is
	/// only ever assigned once, on the main actor, and only ever read here.
	nonisolated(unsafe) private var preferencesObserver: NSObjectProtocol?

	// MARK: - Application Delegate

	/// Applies the "On Launch" preference, but only when nothing else is already on its
	/// way in.
	///
	/// The signal is `NSApplication.launchIsDefaultUserInfoKey`, which Launch Services
	/// sets to `false` when the app was launched *to open something* — a Finder
	/// double-click or `moped <file>` — and `true` for a plain launch. It is known up
	/// front, which is what makes it usable here.
	///
	/// This replaces a `NSDocumentController.shared.documents.isEmpty` guard that was a
	/// race rather than a check. `kAEOpenDocuments` is delivered asynchronously and
	/// `MopedDocument.init(configuration:)` is nonisolated so SwiftUI builds documents
	/// off the main thread; the guard, running on the main actor, could see an empty
	/// array while the CLI's file was still being read, and drop an untitled window on
	/// top of the file the user actually asked for.
	///
	/// The work has to happen here rather than in `applicationOpenUntitledFile(_:)`:
	/// SwiftUI's `DocumentGroup` never consults that hook (verified — neither it nor
	/// `applicationShouldOpenUntitledFile(_:)` is called), and it presents its own open
	/// panel shortly after this returns. Acting now is what preempts that panel; the
	/// "File Open Dialog" case simply declines to act and lets it appear.
	func applicationDidFinishLaunching(_ aNotification: Notification) {
		NSApp.setActivationPolicy(.regular)
		NSApp.activate(ignoringOtherApps: true)
		applySelectedAppIcon()
		startObservingPreferenceChanges()

		// Touching the store is what seeds the themes folder and reads it. Doing it here
		// rather than leaving it to the first `ThemeCatalog` lookup means the folder
		// exists even on a launch that opens no document at all.
		_ = ThemeStore.shared

		let isPlainLaunch = aNotification
			.userInfo?[NSApplication.launchIsDefaultUserInfoKey] as? Bool ?? true
		guard isPlainLaunch else {
			return
		}

		let prefs = Preferences.userShared
		if prefs.reopenPreviousOnLaunch {
			// An exhausted or fully stale session falls back to an empty editor.
			if !reopenPreviousDocuments() {
				NSDocumentController.shared.newDocument(nil)
			}
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

	/// Safe despite appearances. In a plain AppKit document app, answering `.terminateNow`
	/// here is the documented way to *skip* `NSDocumentController`'s unsaved-document review,
	/// which would silently discard edits on Cmd-Q. SwiftUI's `DocumentGroup` does not route
	/// the review through this delegate hook: verified by typing into an untitled document
	/// and pressing Cmd-Q, which still presents the standard "Do you want to keep this new
	/// document?" sheet and leaves the app running when cancelled. `manual-checklist.md`
	/// carries that case so a future SwiftUI change cannot quietly turn this into data loss.
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
			forName: .preferencesChanged,
			object: nil,
			queue: .main
		) { [weak self] _ in
			// Delivered on `.main` per the queue above, so the isolation is real.
			MainActor.assumeIsolated {
				self?.applySelectedAppIcon()
			}
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

	/// Returns whether at least one bookmark resolved and an open was dispatched, so the
	/// caller can fall back to an empty editor when there is nothing left to restore.
	private func reopenPreviousDocuments() -> Bool {
		let entries = Preferences.userShared.lastOpenDocuments
		var refreshedEntries: [RestoredDocument] = []
		var refreshedAny = false
		var openedAny = false

		for entry in entries {
			var isStale = false
			guard let url = try? URL(
				resolvingBookmarkData: entry.bookmark,
				options: .withSecurityScope,
				relativeTo: nil,
				bookmarkDataIsStale: &isStale
			) else {
				refreshedAny = true
				continue
			}

			guard url.startAccessingSecurityScopedResource() else {
				refreshedAny = true
				continue
			}

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

			openedAny = true
			let savedFrame = entry.frame.map { NSRectFromString($0) }
			NSDocumentController.shared.openDocument(
				withContentsOf: url,
				display: true
			) { [weak self] document, _, _ in
				url.stopAccessingSecurityScopedResource()
				if let document, let frame = savedFrame, frame != .zero {
					self?.applyFrame(frame, to: document, retriesLeft: 5)
				}
			}
		}

		if refreshedAny {
			Preferences.userShared.lastOpenDocuments = refreshedEntries
		}
		return openedAny
	}

	private func applyFrame(_ rect: NSRect, to document: NSDocument, retriesLeft: Int) {
		if let window = document.windowControllers.first?.window
			?? NSApp.windows.first(where: { $0.windowController?.document as AnyObject === document }) {
			let onAnyScreen = NSScreen.screens.contains { $0.visibleFrame.intersects(rect) }
			if onAnyScreen {
				window.setFrame(rect, display: true)
			}
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
