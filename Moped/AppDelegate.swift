//
//  AppDelegate.swift
//
//  Moped - A general purpose text editor, small and light.
//  Copyright © 2019-2021 Roberto Machorro. All rights reserved.
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
