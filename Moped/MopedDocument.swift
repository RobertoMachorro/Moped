//
//  MopedDocument.swift
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

import Combine
import SwiftUI
import UniformTypeIdentifiers

final class MopedDocument: ReferenceFileDocument, ObservableObject {
	/// Largest file Moped will open. Benchmarked against the real editor: at this size
	/// a keystroke plus the frame that follows cost ~45 ms with the line-number gutter
	/// visible, inside the ~100 ms "feels instant" budget.
	///
	/// That measurement predates `LineIndex.splice`. The gutter and the highlighter each
	/// used to rebuild a whole line-offset array per keystroke — measured in isolation at
	/// ~6.9 ms apiece at this size, now ~0.09 ms — so the real figure is lower than 45 ms
	/// today. It has not been re-measured end to end, and the limit stays here until it is.
	private static let maxFileLength = 4_194_304 // 4 MB
	/// Threshold at which we start treating a file as "large" and turn off expensive
	/// features (currently syntax highlighting). Measured independently of `maxFileLength`:
	/// highlighting a whole document costs ~51 ms here, ~203 ms at 1 MB and ~821 ms at 4 MB,
	/// so this is the point where it stops being free.
	private static let largeFileThreshold = 262_144 // 256 KB
	/// How long the file watcher stays muted after Moped itself touches the file, so
	/// our own write doesn't come back as an "external change".
	private static let watchSuppressionInterval: TimeInterval = 2.0

	/// Rejection for a file past `maxFileLength`. Keeps the `.fileReadTooLarge` domain and
	/// code so existing error handling still matches, but carries Moped's own wording.
	/// Sizes are formatted rather than hardcoded so the strings survive a limit change.
	private static func fileTooLargeError(actualBytes: Int) -> Error {
		CocoaError(.fileReadTooLarge, userInfo: [
			NSLocalizedDescriptionKey: String(localized: "error.file_too_large.description"),
			NSLocalizedRecoverySuggestionErrorKey: fileTooLargeRecoverySuggestion(actualBytes: actualBytes)
		])
	}

	/// The limit is a power of two, so it needs `.memory` to read as a round "4 MB";
	/// `.file` is decimal and would render it "4.2 MB". The file's own size stays on
	/// `.file` so the number matches what the Finder shows for the same file.
	private static func fileTooLargeRecoverySuggestion(actualBytes: Int) -> String {
		String(
			format: String(localized: "error.file_too_large.recovery_format"),
			Int64(maxFileLength).formatted(.byteCount(style: .memory)),
			Int64(actualBytes).formatted(.byteCount(style: .file))
		)
	}

	/// `ReferenceFileDocument` declares this as a `var`, but the list never changes —
	/// it is derived once from `LanguagesUTI.plist`. Keeping the storage immutable
	/// avoids a mutable ~110-entry global.
	static var readableContentTypes: [UTType] { allReadableContentTypes }

	private static let allReadableContentTypes: [UTType] = {
		var types: [UTType] = [
			.plainText,
			.text,
			.html,
			.data
		]

		if let plistPath = Bundle.main.path(forResource: "LanguagesUTI", ofType: "plist"),
			let languagesFromUTI = NSDictionary(contentsOfFile: plistPath) {
			for key in languagesFromUTI.allKeys {
				if let identifier = key as? String {
					if let type = UTType(identifier) {
						types.append(type)
					}
				}
			}
		}

		var seen = Set<UTType>()
		let unique = types.filter { seen.insert($0).inserted }
		return unique.sorted { ($0.localizedDescription ?? $0.identifier) < ($1.localizedDescription ?? $1.identifier) }
	}()

	@Published var model: TextFileModel

	struct Snapshot {
		let content: String
		let typeName: String
		let typeLanguage: String
		let encoding: String.Encoding
	}

	private var modelCancellable: AnyCancellable?
	private var fileWatcher: FileWatcher?
	private var suppressWatchUntil: Date = .distantPast

	@Published var hasExternalChange = false

	/// Set when a reload was refused; drives the alert in `EditorView`.
	@Published var reloadFailure: String?

	var fileURL: URL? {
		didSet {
			guard oldValue != fileURL else { return }
			updateWatcher()
		}
	}

	private func updateWatcher() {
		fileWatcher?.stop()
		guard let url = fileURL else { return }
		fileWatcher = FileWatcher()
		fileWatcher?.start(url: url) { [weak self] in
			guard let self, Date() > self.suppressWatchUntil else { return }
			self.hasExternalChange = true
		}
	}

	func reloadFromDisk() {
		guard let url = fileURL,
			  let data = try? Data(contentsOf: url) else { return }

		// The file can have grown past the limit since it was opened. Keep what is in
		// memory and say why, rather than reloading unbounded or failing silently.
		guard data.count <= MopedDocument.maxFileLength else {
			refuseReload(because: MopedDocument.fileTooLargeRecoverySuggestion(actualBytes: data.count))
			return
		}

		let previousIsLargeFile = model.isLargeFile
		model.isLargeFile = data.count > MopedDocument.largeFileThreshold
		model.isForceReload = true
		do {
			try model.read(from: data, ofType: model.docTypeName)
		} catch {
			// The file was replaced on disk by something Moped can't decode. Put the
			// large-file flag back and keep the open buffer.
			model.isLargeFile = previousIsLargeFile
			model.isForceReload = false
			refuseReload(because: error.localizedDescription)
			return
		}
		hasExternalChange = false
		suppressWatchUntil = Date().addingTimeInterval(MopedDocument.watchSuppressionInterval)
	}

	/// Leaves the in-memory document untouched, tells the user why, and mutes the
	/// watcher briefly so the same event doesn't re-prompt immediately.
	private func refuseReload(because reason: String) {
		reloadFailure = reason
		hasExternalChange = false
		suppressWatchUntil = Date().addingTimeInterval(MopedDocument.watchSuppressionInterval)
	}

	init(content: String = "") {
		let preferredLanguage = Preferences.userShared.language
		let preferredTypeName = TextFileModel.getUTTypeForLanguage(preferredLanguage)
		model = TextFileModel(
			content: content,
			typeName: preferredTypeName,
			typeLanguage: preferredLanguage
		)
		setupModelObservation()
	}

	init(configuration: ReadConfiguration) throws {
		model = TextFileModel(
			content: "",
			typeName: configuration.contentType.identifier,
			typeLanguage: "plaintext"
		)

		guard let data = configuration.file.regularFileContents else {
			throw CocoaError(.fileReadCorruptFile)
		}

		if data.count > MopedDocument.maxFileLength {
			throw MopedDocument.fileTooLargeError(actualBytes: data.count)
		}

		model.isLargeFile = data.count > MopedDocument.largeFileThreshold
		try model.read(from: data, ofType: configuration.contentType.identifier)
		setupModelObservation()
	}

	func snapshot(contentType: UTType) throws -> Snapshot {
		// If the content has characters the detected encoding can't represent (e.g. CJK
		// added to a file originally read as ASCII), upgrade the live model to UTF-8 so
		// the change persists for the rest of the session.
		if model.content.data(using: model.encoding) == nil {
			model.encoding = .utf8
		}
		return Snapshot(
			content: model.content,
			typeName: contentType.identifier,
			typeLanguage: model.docTypeLanguage,
			encoding: model.encoding
		)
	}

	func fileWrapper(snapshot: Snapshot, configuration: WriteConfiguration) throws -> FileWrapper {
		let typeName = configuration.contentType.identifier
		let snapshotModel = TextFileModel(
			content: snapshot.content,
			typeName: typeName,
			typeLanguage: snapshot.typeLanguage
		)
		snapshotModel.encoding = snapshot.encoding

		guard let data = snapshotModel.data(ofType: typeName) else {
			throw CocoaError(.fileWriteUnknown)
		}

		suppressWatchUntil = Date().addingTimeInterval(MopedDocument.watchSuppressionInterval)
		return .init(regularFileWithContents: data)
	}

	private func setupModelObservation() {
		modelCancellable = model.objectWillChange.sink { [weak self] _ in
			self?.objectWillChange.send()
		}
	}
}
