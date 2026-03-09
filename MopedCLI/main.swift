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
	let environment = ProcessInfo.processInfo.environment
	let shellPWD = environment["PWD"] ?? ""
	let fileManager = FileManager.default
	let currentDirectory = (
		shellPWD.hasPrefix("/") &&
		fileManager.fileExists(atPath: shellPWD)
	)
		? shellPWD
		: fileManager.currentDirectoryPath
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

struct OpenFilesResult {
	let didOpen: Bool
	let errorDescription: String?
}

private func runOpenCommand(arguments: [String]) -> OpenFilesResult {
	let process = Process()
	process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
	process.arguments = arguments
	let errorPipe = Pipe()
	process.standardError = errorPipe

	do {
		try process.run()
		process.waitUntilExit()
		if process.terminationStatus == 0 {
			return OpenFilesResult(didOpen: true, errorDescription: nil)
		}

		let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
		let output = String(data: errorData, encoding: .utf8)?
			.trimmingCharacters(in: .whitespacesAndNewlines)
		let details = output?.isEmpty == false
			? output
			: "open exited with non-zero status."
		return OpenFilesResult(didOpen: false, errorDescription: details)
	} catch {
		return OpenFilesResult(
			didOpen: false,
			errorDescription: error.localizedDescription
		)
	}
}

private func openFiles(_ urls: [URL]) -> OpenFilesResult {
	let arguments = ["-b", CLIConstants.bundleIdentifier] + urls.map(\.path)
	return runOpenCommand(arguments: arguments)
}

private func ensureAppRunning() -> Bool {
	let runningApplications = NSRunningApplication.runningApplications(
		withBundleIdentifier: CLIConstants.bundleIdentifier
	)
	let running = !runningApplications.isEmpty
	if running {
		return true
	}

	let launchResult = runOpenCommand(arguments: ["-b", CLIConstants.bundleIdentifier])
	if !launchResult.didOpen {
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

private func postWaitRequest(sessionID: String, fileURLs: [URL], sessionFilePath: String) {
	let paths = fileURLs.map { $0.path }
	var userInfo: [String: Any] = [
		CLIConstants.sessionIDKey: sessionID,
		CLIConstants.filesKey: paths
	]

	userInfo[CLIConstants.sessionFileKey] = sessionFilePath

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
	let openResult = openFiles(fileURLs)
	if !openResult.didOpen {
		let details = openResult.errorDescription ?? "Unknown error."
		fputs("Unable to open files in Moped: \(details)\n", stderr)
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
guard let sessionFilePath = createSessionFile(sessionID: sessionID) else {
	completionCenter.removeObserver(completionObserver)
	fputs("Unable to create Moped wait session file.\n", stderr)
	exit(1)
}

postWaitRequest(sessionID: sessionID, fileURLs: fileURLs, sessionFilePath: sessionFilePath)
let openResult = openFiles(fileURLs)
if !openResult.didOpen {
	completionCenter.removeObserver(completionObserver)
	let details = openResult.errorDescription ?? "Unknown error."
	fputs("Unable to open files in Moped: \(details)\n", stderr)
	exit(1)
}
postWaitRequest(sessionID: sessionID, fileURLs: fileURLs, sessionFilePath: sessionFilePath)

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
