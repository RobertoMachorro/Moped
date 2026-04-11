//
//  main.swift
//
//  moped-wait — --wait helper for the Moped CLI.
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
//  This sandboxed helper is invoked by the `moped` shell script when the user
//  passes --wait. By the time it runs, the shell script has already handed
//  the files to Moped.app via /usr/bin/open, so this process never touches
//  user files on disk — it only posts a DistributedNotification with the
//  (already absolute) paths so WaitManager can track window closes, then
//  blocks until the session is reported complete.
//

import AppKit

private enum WaitConstants {
	static let bundleIdentifier = "net.machorro.roberto.Moped"
	static let requestNotification = Notification.Name("net.machorro.roberto.Moped.CLIWaitRequest")
	static let completionNotification = Notification.Name("net.machorro.roberto.Moped.CLIWaitComplete")
	static let sessionIDKey = "sessionID"
	static let filesKey = "files"
	static let sessionFileKey = "sessionFilePath"
}

private func usage() -> String {
	"Usage: moped-wait <file>..."
}

private func createSessionFile(sessionID: String) -> String? {
	let basePath = FileManager.default.homeDirectoryForCurrentUser
		.appendingPathComponent("Library/Containers")
		.appendingPathComponent(WaitConstants.bundleIdentifier)
		.appendingPathComponent("Data/Library/Application Support/MopedCLI")
	let fileURL = basePath.appendingPathComponent("\(sessionID).wait")

	do {
		try FileManager.default.createDirectory(
			at: basePath,
			withIntermediateDirectories: true,
			attributes: nil
		)
		try Data().write(to: fileURL, options: .atomic)
		return fileURL.path
	} catch {
		return nil
	}
}

private func postWaitRequest(sessionID: String, paths: [String], sessionFilePath: String) {
	let userInfo: [String: Any] = [
		WaitConstants.sessionIDKey: sessionID,
		WaitConstants.filesKey: paths,
		WaitConstants.sessionFileKey: sessionFilePath
	]

	DistributedNotificationCenter.default().post(
		name: WaitConstants.requestNotification,
		object: nil,
		userInfo: userInfo
	)
}

private func isAppRunning() -> Bool {
	!NSRunningApplication.runningApplications(
		withBundleIdentifier: WaitConstants.bundleIdentifier
	).isEmpty
}

let filePaths = Array(CommandLine.arguments.dropFirst())
if filePaths.isEmpty {
	fputs("\(usage())\n", stderr)
	exit(1)
}

let sessionID = UUID().uuidString
let completionCenter = DistributedNotificationCenter.default()
var didComplete = false
let completionObserver = completionCenter.addObserver(
	forName: WaitConstants.completionNotification,
	object: nil,
	queue: nil
) { notification in
	guard let userInfo = notification.userInfo,
		let id = userInfo[WaitConstants.sessionIDKey] as? String,
		id == sessionID else {
			return
	}

	didComplete = true
}

guard let sessionFilePath = createSessionFile(sessionID: sessionID) else {
	completionCenter.removeObserver(completionObserver)
	fputs("Unable to create Moped wait session file.\n", stderr)
	exit(1)
}

postWaitRequest(sessionID: sessionID, paths: filePaths, sessionFilePath: sessionFilePath)

let runLoop = RunLoop.current
while !didComplete {
	if !FileManager.default.fileExists(atPath: sessionFilePath) {
		break
	}
	if !isAppRunning() {
		break
	}
	runLoop.run(mode: .default, before: Date(timeIntervalSinceNow: 0.1))
}

try? FileManager.default.removeItem(atPath: sessionFilePath)

completionCenter.removeObserver(completionObserver)
