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
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
	// MARK: - Application Delegate
	private var aboutWindowController: NSWindowController?

	func applicationDidFinishLaunching(_ aNotification: Notification) {
		NSApp.setActivationPolicy(.regular)
		NSApp.activate(ignoringOtherApps: true)
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

	func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
		true
	}

}

extension AppDelegate {
	// MARK: - Windows

	@IBAction func showAboutWindow(_ sender: Any?) {
		showAboutWindow()
	}

	private func showAboutWindow() {
		let controller = aboutWindowController ?? makeAboutWindowController()
		aboutWindowController = controller
		controller.showWindow(nil)
		controller.window?.makeKeyAndOrderFront(nil)
	}

	private func makeAboutWindowController() -> NSWindowController {
		let view = AboutView()
		let hostingController = NSHostingController(rootView: view)
		let window = NSWindow(contentViewController: hostingController)
		window.title = "About"
		window.styleMask = [.titled, .closable]
		window.setContentSize(NSSize(width: 340, height: 250))
		window.minSize = NSSize(width: 340, height: 250)
		window.maxSize = NSSize(width: 340, height: 250)
		window.isReleasedWhenClosed = false
		window.center()
		return NSWindowController(window: window)
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
