//
//  ThemeStore.swift
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

import AppKit
import MopedEditor

/// The `.mopedtheme` files on disk, including the ones Moped ships.
///
/// The whole policy is two rules:
///
/// 1. A shipped theme's file is written only if it is absent. Moped never overwrites,
///    never compares versions, never prompts. A theme file is created once and then
///    belongs to whoever edits it.
/// 2. Every `*.mopedtheme` in the folder is loaded. A file that fails to decode is
///    logged and skipped — one bad file must never cost the user the rest of them.
///
/// The consequence of rule 1 is that deleting a shipped theme brings it back on the
/// next launch. That is the honest trade for having no bookkeeping: the content is
/// fixed, so recreating it is idempotent.
///
/// `@MainActor` because the loaded set feeds the settings picker and the open editors,
/// both of which are main-actor bound. Unlike `LanguageCatalog` this cannot be a plain
/// `Sendable` singleton — the folder is re-read while the app runs.
@MainActor
final class ThemeStore {
	static let shared = ThemeStore()

	/// Themes read from `directory`, ordered by filename and deduplicated by name.
	private(set) var themes: [MopedTheme] = []

	/// `…/Application Support/Moped/Themes`. Under the sandbox this resolves inside the
	/// app container, which is the only Application Support Moped can reach — the
	/// entitlements grant user-selected files only, not a home-relative path.
	let directory: URL

	/// Raw bytes of the last read, keyed by filename, so `reload()` can tell an actual
	/// edit from a no-op. Comparing decoded themes would not do: `MopedTheme` is not
	/// `Equatable`, and the interesting change is usually a single colour.
	private var lastRead: [String: Data] = [:]

	private init() {
		let root = FileManager.default
			.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
			?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
		directory = root.appendingPathComponent("Moped/Themes", isDirectory: true)

		seedShippedThemes()
		lastRead = readFiles()
		themes = Self.decode(lastRead)
	}

	/// Re-reads the folder. Posts only when something actually changed, so tabbing back
	/// into Moped does not re-run the highlighter over every open document.
	func reload() {
		let files = readFiles()
		guard files != lastRead else {
			return
		}
		lastRead = files
		themes = Self.decode(files)
		// Reusing the preferences notification rather than introducing a second one:
		// `EditorState` already re-resolves its theme on it, so an edited file reaches
		// open documents without another observer.
		NotificationCenter.default.post(name: .preferencesChanged, object: nil)
	}

	/// Opens the themes folder in Finder. Creating it first covers the case where the
	/// user deleted the folder itself since launch.
	func revealInFinder() {
		try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
		NSWorkspace.shared.open(directory)
	}

	// MARK: - Disk

	private func seedShippedThemes() {
		do {
			try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
		} catch {
			NSLog("Moped: could not create the themes folder at %@: %@", directory.path, "\(error)")
			return
		}

		for theme in MopedTheme.allBuiltIn {
			let url = directory.appendingPathComponent("\(theme.name).\(MopedTheme.fileExtension)")
			guard !FileManager.default.fileExists(atPath: url.path) else {
				continue
			}
			do {
				try theme.fileData().write(to: url, options: .atomic)
			} catch {
				NSLog("Moped: could not write theme %@: %@", url.lastPathComponent, "\(error)")
			}
		}
	}

	private func readFiles() -> [String: Data] {
		let names = (try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? []
		var files: [String: Data] = [:]
		for name in names where name.hasSuffix(".\(MopedTheme.fileExtension)") {
			do {
				files[name] = try Data(contentsOf: directory.appendingPathComponent(name))
			} catch {
				// A theme that vanishes from the picker should always be explainable
				// from the log; a file that cannot be read at all is no different from
				// one that cannot be decoded.
				NSLog("Moped: could not open theme %@: %@", name, "\(error)")
			}
		}
		return files
	}

	/// Filename order decides which of two files claiming the same theme name wins. Any
	/// deterministic rule would do; this one is the only rule a user can predict.
	///
	/// Names are claimed case-insensitively because `ThemeCatalog` looks them up that
	/// way. Letting `Nord` and `nord` both load would put two entries in the picker that
	/// resolve to the same theme, and not necessarily the one that was clicked.
	private static func decode(_ files: [String: Data]) -> [MopedTheme] {
		var themes: [MopedTheme] = []
		var claimed: Set<String> = []

		for (filename, data) in files.sorted(by: { $0.key < $1.key }) {
			do {
				let theme = try MopedTheme(data: data)
				guard claimed.insert(theme.name.lowercased()).inserted else {
					NSLog("Moped: %@ claims the theme name \"%@\", already taken — skipping.", filename, theme.name)
					continue
				}
				themes.append(theme)
			} catch {
				NSLog("Moped: could not read theme %@: %@", filename, "\(error)")
			}
		}
		return themes
	}
}
