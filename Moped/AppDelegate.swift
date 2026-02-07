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
	// MARK: - Application Delegate

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
