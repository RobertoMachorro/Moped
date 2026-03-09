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

private struct PreferenceOption: Hashable {
	let value: String
	let label: String
}

struct PreferencesView: View {
	@ObservedObject var preferences: Preferences

	private let languages: [String]
	private let themes: [String]
	private let fonts: [String]
	private let fontSizes: [String]
	private let wrapOptions: [PreferenceOption]
	private let lineNumberRulerOptions: [PreferenceOption]
	private let appIconOptions = Preferences.AppIcon.allCases.map { $0.rawValue }

	init(preferences: Preferences) {
		self.preferences = preferences

		let catalog = HighlightrCatalog.shared
		languages = catalog.supportedLanguages
		themes = catalog.availableThemes
		fonts = NSFontManager.shared.availableFonts.sorted()
		fontSizes = (9...24).map { String($0) }
		wrapOptions = [
			PreferenceOption(value: "Yes", label: String(localized: "option.yes")),
			PreferenceOption(value: "No", label: String(localized: "option.no"))
		]
		lineNumberRulerOptions = [
			PreferenceOption(value: "Yes", label: String(localized: "option.yes")),
			PreferenceOption(value: "No", label: String(localized: "option.no"))
		]
	}

	var body: some View {
		VStack(alignment: .leading, spacing: 12) {
			PreferenceRow(
				title: "pref.language.title",
				selection: Binding(
					get: { preferences.language },
					set: { preferences.language = $0 }
				),
				options: languages.map { PreferenceOption(value: $0, label: $0) }
			)

			PreferenceRow(
				title: "pref.theme.title",
				selection: Binding(
					get: { preferences.theme },
					set: { preferences.theme = $0 }
				),
				options: themes.map { PreferenceOption(value: $0, label: $0) }
			)

			PreferenceRow(
				title: "pref.font.title",
				selection: Binding(
					get: { preferences.font },
					set: { preferences.font = $0 }
				),
				options: fonts.map { PreferenceOption(value: $0, label: $0) }
			)

			PreferenceRow(
				title: "pref.font_size.title",
				selection: Binding(
					get: { preferences.fontSize },
					set: { preferences.fontSize = $0 }
				),
				options: fontSizes.map { PreferenceOption(value: $0, label: $0) }
			)

			PreferenceRow(
				title: "pref.word_wrap.title",
				selection: Binding(
					get: { preferences.lineWrap },
					set: { preferences.lineWrap = $0 }
				),
				options: wrapOptions
			)

			PreferenceRow(
				title: "pref.line_numbers.title",
				selection: Binding(
					get: { preferences.showLineNumberRuler },
					set: { preferences.showLineNumberRuler = $0 }
				),
				options: lineNumberRulerOptions
			)

			PreferenceRow(
				title: "pref.active_icon.title",
				selection: Binding(
					get: { preferences.appIcon },
					set: { preferences.appIcon = $0 }
				),
				options: appIconOptions.map { PreferenceOption(value: $0, label: $0) }
			)
		}
		.padding(20)
		.frame(width: 345, height: 268, alignment: .topLeading)
	}
}

private struct PreferenceRow: View {
	let title: LocalizedStringKey
	@Binding var selection: String
	let options: [PreferenceOption]

	var body: some View {
		HStack(alignment: .center, spacing: 12) {
			Text(title)
				.frame(width: 90, alignment: .leading)
			Picker("", selection: $selection) {
				ForEach(options, id: \.self) { option in
					Text(option.label)
						.tag(option.value)
				}
			}
			.labelsHidden()
			.frame(maxWidth: .infinity, alignment: .leading)
		}
	}
}
