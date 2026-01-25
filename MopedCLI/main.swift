import AppKit

private enum CLIConstants {
	static let bundleIdentifier = "net.machorro.roberto.Moped"
	static let requestNotification = Notification.Name("net.machorro.roberto.Moped.CLIWaitRequest")
	static let completionNotification = Notification.Name("net.machorro.roberto.Moped.CLIWaitComplete")
	static let sessionIDKey = "sessionID"
	static let filesKey = "files"
	static let sessionFileKey = "sessionFilePath"
}

private struct CLIArguments {
	let waitMode: Bool
	let filePaths: [String]

	init(_ arguments: [String]) {
		var waitMode = false
		var filePaths: [String] = []

		for argument in arguments {
			if argument == "--wait" {
				waitMode = true
			} else {
				filePaths.append(argument)
			}
		}

		self.waitMode = waitMode
		self.filePaths = filePaths
	}
}

private func usage() -> String {
	"Usage: moped [--wait] <file>..."
}

private func resolveFileURLs(from paths: [String]) -> [URL] {
	let currentDirectory = FileManager.default.currentDirectoryPath
	let currentDirectoryPath = currentDirectory as NSString

	return paths.map { path in
		let expanded = (path as NSString).expandingTildeInPath
		let absolute = expanded.hasPrefix("/")
			? expanded
			: currentDirectoryPath.appendingPathComponent(expanded)
		return URL(fileURLWithPath: absolute)
			.resolvingSymlinksInPath()
			.standardizedFileURL
	}
}

private func openFiles(_ urls: [URL]) -> Bool {
	NSWorkspace.shared.open(
		urls,
		withAppBundleIdentifier: CLIConstants.bundleIdentifier,
		options: [],
		additionalEventParamDescriptor: nil,
		launchIdentifiers: nil
	)
}

private func ensureAppRunning() -> Bool {
	let runningApplications = NSRunningApplication.runningApplications(
		withBundleIdentifier: CLIConstants.bundleIdentifier
	)
	let running = !runningApplications.isEmpty
	if running {
		return true
	}

	let launched = NSWorkspace.shared.launchApplication(
		withBundleIdentifier: CLIConstants.bundleIdentifier,
		options: [],
		additionalEventParamDescriptor: nil,
		launchIdentifier: nil
	)
	if !launched {
		return false
	}

	let deadline = Date().addingTimeInterval(5.0)
	while Date() < deadline {
		let nowRunning = !NSRunningApplication.runningApplications(
			withBundleIdentifier: CLIConstants.bundleIdentifier
		).isEmpty
		if nowRunning {
			return true
		}
		Thread.sleep(forTimeInterval: 0.1)
	}

	return false
}

private func isAppRunning() -> Bool {
	!NSRunningApplication.runningApplications(
		withBundleIdentifier: CLIConstants.bundleIdentifier
	).isEmpty
}

private func postWaitRequest(sessionID: String, fileURLs: [URL], sessionFilePath: String?) {
	let paths = fileURLs.map { $0.path }
	var userInfo: [String: Any] = [
		CLIConstants.sessionIDKey: sessionID,
		CLIConstants.filesKey: paths
	]

	if let sessionFilePath = sessionFilePath {
		userInfo[CLIConstants.sessionFileKey] = sessionFilePath
	}

	DistributedNotificationCenter.default().post(
		name: CLIConstants.requestNotification,
		object: nil,
		userInfo: userInfo
	)
}

private func createSessionFile(sessionID: String) -> String? {
	let basePath = FileManager.default.homeDirectoryForCurrentUser
		.appendingPathComponent("Library/Containers")
		.appendingPathComponent(CLIConstants.bundleIdentifier)
		.appendingPathComponent("Data/Library/Application Support/MopedCLI")
	let fileURL = basePath.appendingPathComponent("\(sessionID).wait")

	do {
		try FileManager.default.createDirectory(
			at: basePath,
			withIntermediateDirectories: true,
			attributes: nil
		)
		let emptyData = Data()
		try emptyData.write(to: fileURL, options: .atomic)
		return fileURL.path
	} catch {
		return nil
	}
}

private let parsedArguments = CLIArguments(Array(CommandLine.arguments.dropFirst()))
if parsedArguments.filePaths.isEmpty {
	fputs("\(usage())\n", stderr)
	exit(1)
}

let fileURLs = resolveFileURLs(from: parsedArguments.filePaths)

if !parsedArguments.waitMode {
	if !openFiles(fileURLs) {
		fputs("Unable to open files in Moped.\n", stderr)
		exit(1)
	}
	exit(0)
}

let sessionID = UUID().uuidString
let completionCenter = DistributedNotificationCenter.default()
var didComplete = false
let completionObserver = completionCenter.addObserver(
	forName: CLIConstants.completionNotification,
	object: nil,
	queue: nil
) { notification in
	guard let userInfo = notification.userInfo,
		let id = userInfo[CLIConstants.sessionIDKey] as? String,
		id == sessionID else {
			return
	}

	didComplete = true
}

if !ensureAppRunning() {
	completionCenter.removeObserver(completionObserver)
	fputs("Unable to launch Moped.\n", stderr)
	exit(1)
}

let runLoop = RunLoop.current
let sessionFilePath = createSessionFile(sessionID: sessionID)
postWaitRequest(sessionID: sessionID, fileURLs: fileURLs, sessionFilePath: sessionFilePath)
if !openFiles(fileURLs) {
	completionCenter.removeObserver(completionObserver)
	fputs("Unable to open files in Moped.\n", stderr)
	exit(1)
}
postWaitRequest(sessionID: sessionID, fileURLs: fileURLs, sessionFilePath: sessionFilePath)

while !didComplete {
	if let sessionFilePath = sessionFilePath,
		!FileManager.default.fileExists(atPath: sessionFilePath) {
		break
	}
	if !isAppRunning() {
		break
	}
	runLoop.run(mode: .default, before: Date(timeIntervalSinceNow: 0.1))
}

if let sessionFilePath = sessionFilePath {
	try? FileManager.default.removeItem(atPath: sessionFilePath)
}

completionCenter.removeObserver(completionObserver)
