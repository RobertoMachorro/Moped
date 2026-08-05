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

/// `@unchecked Sendable` is deliberate and is the one suppression in this target.
///
/// `ReferenceFileDocument` refines `Sendable` while declaring `init(configuration:)`
/// and `fileWrapper(snapshot:configuration:)` nonisolated, so SwiftUI can read and
/// write off the main thread — worth keeping for a 4 MB file. A reference document
/// therefore cannot satisfy the checker: it exists to hold a mutable model. Apple marks
/// the protocol `@preconcurrency` for exactly this reason.
///
/// What actually happens is a handoff, not sharing: `init(configuration:)` builds the
/// model and populates it before any view sees the document, and from then on every
/// mutation arrives through SwiftUI bindings on the main actor. The one field written
/// off-main afterwards is `suppressWatchUntil`, from `fileWrapper` during a save, and it
/// is a `Date` guarding a debounce — a stale read re-prompts a reload at worst.
///
/// `snapshot(contentType:)` is the other method the save can call off the main thread. It
/// reads the model to build the snapshot, which is the handoff working as intended, and
/// hops to the main actor for the one thing it writes back — see
/// `adoptContentTypeOnFirstSave`.
final class MopedDocument: ReferenceFileDocument, ObservableObject, @unchecked Sendable {
	/// Largest file Moped will open.
	///
	/// Re-measured after `LineIndex.splice`, driving the real editor with the gutter
	/// visible (median of 25 keystrokes; open = encoding detection, decode, layout and
	/// first frame):
	///
	///     size     keystroke   open
	///     256 KB     5.9 ms    14 ms
	///     4 MB       5.5 ms    87 ms
	///     16 MB      6.0 ms   321 ms
	///
	/// Keystroke cost is now flat in document size — it used to grow, which is what this
	/// limit was originally protecting against, and that reason no longer holds. Open cost
	/// is linear at roughly 20 ms/MB and is what actually bounds the limit now.
	///
	/// 4 MB is therefore conservative rather than necessary; the numbers support raising
	/// it. Left as-is deliberately: memory is the untested axis — a 16 MB document also
	/// carries its text storage, attributes and undo stack — and the measurements come
	/// from one Apple Silicon machine.
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
	/// code so existing error handling still matches, and carries Moped's own wording as
	/// the recovery suggestion.
	///
	/// Only the recovery suggestion, deliberately: this error is thrown from
	/// `init(configuration:)`, and `NSDocumentController` replaces any
	/// `NSLocalizedDescriptionKey` with its own "The document … could not be opened"
	/// wrapper. A description here would be translated into 13 languages and shown to
	/// nobody. The reload path never sees this error — it refuses on size before reading.
	private static func fileTooLargeError(actualBytes: Int) -> Error {
		CocoaError(.fileReadTooLarge, userInfo: [
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

	/// Immutable reference, assigned once per document. Edits arrive as changes *inside*
	/// the model, which `setupModelObservation` forwards to this object's
	/// `objectWillChange` — nothing ever swaps the model out, so `@Published var` only
	/// ever added mutable state to a `Sendable`-conforming type.
	let model: TextFileModel

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

	/// `fileURL` is only ever assigned from the `onChange` in `MopedApp`, which is
	/// SwiftUI view code and therefore main-actor. The document itself cannot be
	/// isolated — `ReferenceFileDocument` declares `init(configuration:)` and
	/// `fileWrapper(snapshot:configuration:)` nonisolated so reads and writes can run
	/// off the main thread, which for a 4 MB file is the point — so the isolation is
	/// asserted here instead.
	private func updateWatcher() {
		MainActor.assumeIsolated {
			installWatcher()
		}
	}

	@MainActor
	private func installWatcher() {
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
		adoptContentTypeOnFirstSave(contentType)
		return Snapshot(
			content: model.content,
			typeName: contentType.identifier,
			typeLanguage: model.docTypeLanguage,
			encoding: model.encoding
		)
	}

	/// An untitled document is saved with whatever type the user picked in the Save panel,
	/// which is the first time it has a type at all. Adopt it so the editor highlights what
	/// was actually written instead of staying on the new-document default.
	///
	/// Restricted to the first save deliberately. On a document that already has a URL, a
	/// plain Cmd-S would otherwise reset the language whenever `contentType` is derived from
	/// the file on disk rather than from the type the status-bar picker set — which is how a
	/// `.txt` the user is editing as Python would silently fall back to `plaintext`.
	///
	/// The decision is made here, on whatever thread the save runs on, but applied on the
	/// main actor: `snapshot(contentType:)` carries no isolation in the protocol, and the
	/// type and language are `@Published`. Reading the model here is what this method
	/// already exists to do; publishing from the save's thread is not.
	private func adoptContentTypeOnFirstSave(_ contentType: UTType) {
		let typeName = contentType.identifier
		let previousTypeName = model.docTypeName
		guard fileURL == nil, typeName != previousTypeName else {
			return
		}
		let language = model.getLanguageForType(typeName: typeName)

		DispatchQueue.main.async { [self] in
			MainActor.assumeIsolated {
				adoptTypeName(typeName, language: language, ifStillAt: previousTypeName)
			}
		}
	}

	/// Applies the adopted type unless the picker moved while the write was in flight —
	/// an explicit choice by the user beats one inferred from the save.
	@MainActor
	private func adoptTypeName(_ typeName: String, language: String, ifStillAt previousTypeName: String) {
		guard model.docTypeName == previousTypeName else {
			return
		}
		model.docTypeName = typeName
		model.docTypeLanguage = language
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
