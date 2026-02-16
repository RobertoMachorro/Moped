//
//  PreferencesView.swift
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

import Highlightr
import SwiftUI

struct PreferencesView: View {
	@ObservedObject var preferences: Preferences

	private let languages: [String]
	private let themes: [String]
	private let fonts: [String]
	private let fontSizes: [String]
	private let wrapOptions = ["Yes", "No"]
	private let lineNumberRulerOptions = ["Yes", "No"]
	private let appIconOptions = Preferences.AppIcon.allCases.map { $0.rawValue }

	init(preferences: Preferences) {
		self.preferences = preferences

		let highlightrTextStorage = CodeAttributedString()
		languages = highlightrTextStorage.highlightr.supportedLanguages().sorted()
		themes = highlightrTextStorage.highlightr.availableThemes().sorted()
		fonts = NSFontManager.shared.availableFonts.sorted()
		fontSizes = (9...24).map { String($0) }
	}

	var body: some View {
		VStack(alignment: .leading, spacing: 12) {
			PreferenceRow(
				title: "Language:",
				selection: Binding(
					get: { preferences.language },
					set: { preferences.language = $0 }
				),
				options: languages
			)

			PreferenceRow(
				title: "Theme:",
				selection: Binding(
					get: { preferences.theme },
					set: { preferences.theme = $0 }
				),
				options: themes
			)

			PreferenceRow(
				title: "Font:",
				selection: Binding(
					get: { preferences.font },
					set: { preferences.font = $0 }
				),
				options: fonts
			)

			PreferenceRow(
				title: "Font Size:",
				selection: Binding(
					get: { preferences.fontSize },
					set: { preferences.fontSize = $0 }
				),
				options: fontSizes
			)

			PreferenceRow(
				title: "Word Wrap:",
				selection: Binding(
					get: { preferences.lineWrap },
					set: { preferences.lineWrap = $0 }
				),
				options: wrapOptions
			)

			PreferenceRow(
				title: "Line Numbers:",
				selection: Binding(
					get: { preferences.showLineNumberRuler },
					set: { preferences.showLineNumberRuler = $0 }
				),
				options: lineNumberRulerOptions
			)

			PreferenceRow(
				title: "App Icon:",
				selection: Binding(
					get: { preferences.appIcon },
					set: { preferences.appIcon = $0 }
				),
				options: appIconOptions
			)
		}
		.padding(20)
		.frame(width: 345, height: 268, alignment: .topLeading)
	}
}

private struct PreferenceRow: View {
	let title: String
	@Binding var selection: String
	let options: [String]

	var body: some View {
		HStack(alignment: .center, spacing: 12) {
			Text(title)
				.frame(width: 90, alignment: .leading)
			Picker("", selection: $selection) {
				ForEach(options, id: \.self) { option in
					Text(option)
				}
			}
			.labelsHidden()
			.frame(maxWidth: .infinity, alignment: .leading)
		}
	}
}
