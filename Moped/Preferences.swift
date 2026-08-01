//
//  Preferences.swift
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
import Foundation

struct RestoredDocument: Codable {
	let bookmark: Data
	let frame: String?
}

extension Notification.Name {
	/// Posted by `Preferences` on every write. `EditorState` re-reads the editor
	/// settings; `AppDelegate` re-applies the app icon.
	static let preferencesChanged = Notification.Name("PreferencesChanged")
}

class Preferences: NSObject, ObservableObject {
	enum DefaultIndentation: String, CaseIterable {
		case tab
		case twoSpaces
		case fourSpaces
	}

	enum AppIcon: String, CaseIterable {
		case defaultIcon = "Default"
		case pink = "Pink"
		case black = "Black"
		case red = "Red"
		case rainbow = "Rainbow"
		case beige = "Beige"

		/// Display name for the preferences picker. `rawValue` stays the stored
		/// preference value, so translating these never invalidates a saved setting.
		var localizedLabel: String {
			switch self {
			case .defaultIcon:
				return String(localized: "option.icon.default")
			case .pink:
				return String(localized: "option.icon.pink")
			case .black:
				return String(localized: "option.icon.black")
			case .red:
				return String(localized: "option.icon.red")
			case .rainbow:
				return String(localized: "option.icon.rainbow")
			case .beige:
				return String(localized: "option.icon.beige")
			}
		}

		var appIconSetName: String {
			switch self {
			case .defaultIcon:
				return "AppIconDefault"
			case .pink:
				return "AppIconPink"
			case .black:
				return "AppIconBlack"
			case .red:
				return "AppIconRed"
			case .rainbow:
				return "AppIconRainbow"
			case .beige:
				return "AppIconBeige"
			}
		}
	}

	// MARK: - Singleton with Custom Setup

	static let userShared: Preferences = {
		let shared = Preferences()
		return shared
	}()

	// MARK: - Preferences / Properties

	@objc dynamic var defaultIndentation: String {
		get {
			let stored = getStringValue(
				forKey: "defaultIndentation",
				otherwiseUse: DefaultIndentation.tab.rawValue
			)
			return DefaultIndentation(rawValue: stored)?.rawValue ?? DefaultIndentation.tab.rawValue
		}
		set {
			let validated = DefaultIndentation(rawValue: newValue)?.rawValue
				?? DefaultIndentation.tab.rawValue
			setStringValue(forKey: "defaultIndentation", to: validated)
		}
	}

	var selectedDefaultIndentation: DefaultIndentation {
		DefaultIndentation(rawValue: defaultIndentation) ?? .tab
	}

	/// Validated on read, like `defaultIndentation` and `appIcon`. The picker now offers
	/// only languages that highlight, so a value saved when it listed every UTI name
	/// (`lua`, `haskell`, …) would otherwise select nothing and render blank.
	@objc dynamic var language: String {
		get {
			let stored = getStringValue(forKey: "language", otherwiseUse: "plaintext")
			return LanguageCatalog.shared.supportedLanguages.contains(stored) ? stored : "plaintext"
		}
		set {
			setStringValue(forKey: "language", to: newValue)
		}
	}

	@objc dynamic var theme: String {
		get {
			getStringValue(forKey: "theme", otherwiseUse: "xcode")
		}
		set {
			setStringValue(forKey: "theme", to: newValue)
		}
	}

	@objc dynamic var font: String {
		get {
			getStringValue(forKey: "font", otherwiseUse: "Menlo")
		}
		set {
			setStringValue(forKey: "font", to: newValue)
		}
	}

	@objc dynamic var fontSize: String {
		get {
			getStringValue(forKey: "fontSize", otherwiseUse: "13")
		}
		set {
			setStringValue(forKey: "fontSize", to: newValue)
		}
	}

	@objc dynamic var lineWrap: String {
		get {
			getStringValue(forKey: "lineWrap", otherwiseUse: "Yes")
		}
		set {
			setStringValue(forKey: "lineWrap", to: newValue)
		}
	}

	@objc dynamic var showLineNumberRuler: String {
		get {
			getStringValue(forKey: "showLineNumberRuler", otherwiseUse: "Yes")
		}
		set {
			setStringValue(forKey: "showLineNumberRuler", to: newValue)
		}
	}

	@objc dynamic var launchBehavior: String {
		get {
			getStringValue(forKey: "launchBehavior", otherwiseUse: "FileOpenDialog")
		}
		set {
			setStringValue(forKey: "launchBehavior", to: newValue)
		}
	}

	@objc dynamic var appIcon: String {
		get {
			let selectedIconName = getStringValue(
				forKey: "appIcon",
				otherwiseUse: AppIcon.defaultIcon.rawValue
			)
			return AppIcon(rawValue: selectedIconName)?.rawValue ?? AppIcon.defaultIcon.rawValue
		}
		set {
			let selectedIconName = AppIcon(rawValue: newValue)?.rawValue
				?? AppIcon.defaultIcon.rawValue
			setStringValue(forKey: "appIcon", to: selectedIconName)
		}
	}

	// MARK: - UserDefaults Helpers

	/// The stored value is always one of the plain integer strings the preferences
	/// picker offers, so a locale-aware `NumberFormatter` buys nothing here. The
	/// fallback matches the `fontSize` default rather than the low end of the range.
	var fontSizeFloat: CGFloat {
		guard let size = Double(fontSize) else {
			return 13
		}
		return CGFloat(size)
	}

	var openEmptyOnLaunch: Bool {
		return launchBehavior == "EmptyEditor"
	}

	var reopenPreviousOnLaunch: Bool {
		return launchBehavior == "ReopenPrevious"
	}

	var lastOpenDocuments: [RestoredDocument] {
		get {
			guard let data = UserDefaults.standard.data(forKey: "lastOpenDocuments"),
				  let decoded = try? JSONDecoder().decode([RestoredDocument].self, from: data) else {
				return []
			}
			return decoded
		}
		set {
			guard let data = try? JSONEncoder().encode(newValue) else { return }
			UserDefaults.standard.set(data, forKey: "lastOpenDocuments")
		}
	}

	var doLineWrap: Bool {
		return lineWrap == "Yes"
	}

	var doShowLineNumberRuler: Bool {
		return showLineNumberRuler == "Yes"
	}

	var selectedAppIcon: AppIcon {
		return AppIcon(rawValue: appIcon) ?? .defaultIcon
	}

	func getStringValue(forKey key: String, otherwiseUse backup: String) -> String {
		UserDefaults.standard.string(forKey: key) ?? backup
	}

	func setStringValue(forKey key: String, to value: String) {
		objectWillChange.send()
		UserDefaults.standard.set(value, forKey: key)
		NotificationCenter.default.post(name: .preferencesChanged, object: nil)
	}
}
