//
//  AppDelegate.swift
//
//  Moped - A general purpose text editor, small and light.
//  Copyright © 2019 Roberto Machorro. All rights reserved.
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

	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}

	func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
		return .terminateNow
	}

	// MARK: - Help Menu Actions

	@IBAction func linkToLicense(_ sender: Any) {
		if let url = URL(string: "https://www.gnu.org/licenses/") {
			NSWorkspace.shared.open(url)
		}
	}

	@IBAction func linkToSources(_ sender: Any) {
		if let url = URL(string: "https://github.com/RobertoMachorro/MacPad") {
			NSWorkspace.shared.open(url)
		}
	}

	@IBAction func linkToIssues(_ sender: Any) {
		if let url = URL(string: "https://github.com/RobertoMachorro/MacPad/issues") {
			NSWorkspace.shared.open(url)
		}
	}

	@IBAction func linkToIconSite(_ sender: Any) {
		if let url = URL(string: "http://www.iconarchive.com/show/small-n-flat-icons-by-paomedia/notepad-icon.html") {
			NSWorkspace.shared.open(url)
		}
	}

}
