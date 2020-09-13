//
//  Preferences.swift
//
//  Moped - A general purpose text editor, small and light.
//  Copyright © 2019-2020 Roberto Machorro. All rights reserved.
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

import Foundation

class Preferences: NSObject {
	// MARK: - Singleton with Custom Setup

	static let userShared: Preferences = {
		let shared = Preferences()
		return shared
	}()

	// MARK: - Preferences / Properties

	@objc dynamic var language: String {
		get {
			getStringValue(forKey: "language", otherwiseUse: "plaintext")
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

	// MARK: - UserDefaults Helpers

	var fontSizeFloat: CGFloat {
		guard let number = NumberFormatter().number(from: fontSize) else {
			return CGFloat(9)
		}
		return CGFloat(truncating: number)
	}

	func getStringValue(forKey key: String, otherwiseUse backup: String) -> String {
		UserDefaults.standard.string(forKey: key) ?? backup
	}

	func setStringValue(forKey key: String, to value: String) {
		UserDefaults.standard.set(value, forKey: key)
		NotificationCenter.default.post(name: Notification.Name(rawValue: "PreferencesChanged"), object: nil)
	}
}
