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

import MopedEditor
import SwiftUI

private struct PreferenceOption: Hashable {
	let value: String
	let label: String
}

/// Sidebar sections, in display order. Grouping by purpose keeps unrelated settings
/// from competing for the same visual weight the way one flat list did.
private enum SettingsSection: String, CaseIterable, Identifiable {
	case general
	case appearance
	case editing
	case advanced

	var id: String { rawValue }

	var title: LocalizedStringKey {
		switch self {
		case .general:    return "pref.section.general"
		case .appearance: return "pref.section.appearance"
		case .editing:    return "pref.section.editing"
		case .advanced:   return "pref.section.advanced"
		}
	}

	var symbol: String {
		switch self {
		case .general:    return "gearshape"
		case .appearance: return "paintpalette"
		case .editing:    return "chevron.left.forwardslash.chevron.right"
		case .advanced:   return "slider.horizontal.3"
		}
	}
}

struct PreferencesView: View {
	@ObservedObject var preferences: Preferences

	/// Lives in the view, not in `Preferences`: that type documents at its declaration
	/// that it must stay free of stored properties.
	@State private var section: SettingsSection = .general

	/// Enumerating every installed font is expensive enough to do once per launch
	/// rather than once per view init, which the sidebar makes far more frequent.
	private static let allFonts: [String] = NSFontManager.shared.availableFonts.sorted()
	private static let monospacedFonts: [String] =
		(NSFontManager.shared.availableFontNames(with: .fixedPitchFontMask) ?? []).sorted()

	private let languages: [PreferenceOption]
	private let themes: [PreferenceOption]
	private let fontSizes: [PreferenceOption]
	private let launchBehaviorOptions: [PreferenceOption]
	private let defaultIndentationOptions: [PreferenceOption]
	private let appIconOptions = Preferences.AppIcon.allCases.map {
		PreferenceOption(value: $0.rawValue, label: $0.localizedLabel)
	}

	init(preferences: Preferences) {
		self.preferences = preferences

		languages = LanguageCatalog.shared.supportedLanguages.map {
			PreferenceOption(value: $0, label: $0)
		}
		themes = MopedTheme.selectableNames.map {
			PreferenceOption(value: $0, label: ThemeCatalog.localizedName(for: $0))
		}
		fontSizes = (9...24).map { PreferenceOption(value: String($0), label: String($0)) }
		launchBehaviorOptions = [
			PreferenceOption(value: "FileOpenDialog", label: String(localized: "option.file_open_dialog")),
			PreferenceOption(value: "EmptyEditor", label: String(localized: "option.empty_editor")),
			PreferenceOption(value: "ReopenPrevious", label: String(localized: "option.reopen_previous"))
		]
		defaultIndentationOptions = [
			PreferenceOption(value: Preferences.DefaultIndentation.tab.rawValue, label: String(localized: "option.indent.tab")),
			PreferenceOption(value: Preferences.DefaultIndentation.twoSpaces.rawValue, label: String(localized: "option.indent.two_spaces")),
			PreferenceOption(value: Preferences.DefaultIndentation.fourSpaces.rawValue, label: String(localized: "option.indent.four_spaces"))
		]
	}

	// MARK: - Layout

	var body: some View {
		HStack(spacing: 0) {
			List(SettingsSection.allCases, selection: sidebarSelection) { item in
				Label(item.title, systemImage: item.symbol)
					.tag(item)
			}
			.listStyle(.sidebar)
			.frame(width: 170)

			Divider()

			ScrollView {
				detail
					.padding(20)
					.frame(maxWidth: .infinity, alignment: .leading)
			}
		}
		// Sized by measurement, not by eye. The binding constraints are pt-BR's "At
		// startup" popup (581pt including padding — the widest control in any of the 13
		// locales) and Hindi's Appearance pane (206pt tall, Devanagari has taller line
		// boxes). English needs far less, but one fixed window has to fit the worst case
		// or that popup silently truncates.
		.frame(width: 590, height: 210)
		.navigationTitle("window.settings.title")
	}

	/// `List` hands back `nil` when a row is deselected, but the detail pane always
	/// needs a section, so a deselect keeps whichever one was showing.
	private var sidebarSelection: Binding<SettingsSection?> {
		Binding(
			get: { section },
			set: { section = $0 ?? section }
		)
	}

	@ViewBuilder
	private var detail: some View {
		VStack(alignment: .leading, spacing: 16) {
			Text(section.title)
				.font(.title2)
				.bold()

			switch section {
			case .general:    generalPane
			case .appearance: appearancePane
			case .editing:    editingPane
			case .advanced:   advancedPane
			}
		}
	}

	// MARK: - Panes

	private var generalPane: some View {
		settingsGrid {
			GridRow {
				label("pref.launch_behavior.title")
				picker(binding(\.launchBehavior), options: launchBehaviorOptions)
			}
			GridRow {
				label("pref.active_icon.title")
				picker(binding(\.appIcon), options: appIconOptions)
			}
		}
	}

	private var appearancePane: some View {
		settingsGrid {
			GridRow {
				label("pref.theme.title")
				picker(binding(\.theme), options: themes)
			}
			GridRow {
				label("pref.font.title")
				picker(binding(\.font), options: fontOptions)
			}
			GridRow {
				emptyLabel
				checkbox("pref.monospaced_only.title", yesNo(\.monospacedFontsOnly))
			}
			GridRow {
				label("pref.font_size.title")
				picker(binding(\.fontSize), options: fontSizes)
					.fixedSize()
			}
		}
	}

	private var editingPane: some View {
		settingsGrid {
			GridRow {
				label("pref.language.title")
				picker(binding(\.language), options: languages)
			}
			GridRow {
				emptyLabel
				checkbox("pref.word_wrap.title", yesNo(\.lineWrap))
			}
			GridRow {
				emptyLabel
				checkbox("pref.line_numbers.title", yesNo(\.showLineNumberRuler))
			}
			GridRow {
				label("pref.default_indentation.title")
				picker(binding(\.defaultIndentation), options: defaultIndentationOptions)
			}
		}
	}

	private var advancedPane: some View {
		settingsGrid {
			GridRow {
				label("pref.default_editor.title")
				Button("pref.default_editor.button") {
					AppActions.shared.showDefaultEditorSelector()
				}
				.fixedSize()
			}
		}
	}

	// MARK: - Row building

	/// `Grid` sizes the label column to its widest member, so labels and controls line
	/// up in every locale — which the old fixed-width label frame could not do.
	private func settingsGrid<Content: View>(@ViewBuilder rows: () -> Content) -> some View {
		Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 12, verticalSpacing: 12) {
			rows()
		}
	}

	private func label(_ title: LocalizedStringKey) -> some View {
		Text(title)
			.gridColumnAlignment(.leading)
	}

	/// Placeholder for a row whose control is self-labelling, so it still lands in the
	/// control column rather than starting at the label column.
	private var emptyLabel: some View {
		Color.clear
			.gridCellUnsizedAxes([.horizontal, .vertical])
	}

	private func picker(_ selection: Binding<String>, options: [PreferenceOption]) -> some View {
		Picker("", selection: selection) {
			ForEach(options, id: \.value) { option in
				Text(option.label)
					.tag(option.value)
			}
		}
		.labelsHidden()
		.frame(maxWidth: .infinity, alignment: .leading)
	}

	/// A self-labelling checkbox for the control column.
	///
	/// `fixedSize(horizontal:)` is load-bearing. A `Text` advertises a flexible ideal
	/// width because it is willing to wrap, so `Grid` sizes the control column to the
	/// pickers and then squeezes the checkbox caption onto two lines — even with the
	/// window half empty beside it. Refusing to compress makes the caption report its
	/// true width, so the column is sized to fit it.
	private func checkbox(_ title: LocalizedStringKey, _ isOn: Binding<Bool>) -> some View {
		Toggle(title, isOn: isOn)
			.toggleStyle(.checkbox)
			.fixedSize(horizontal: true, vertical: false)
	}

	// MARK: - Bindings

	private func binding(_ keyPath: ReferenceWritableKeyPath<Preferences, String>) -> Binding<String> {
		Binding(
			get: { preferences[keyPath: keyPath] },
			set: { preferences[keyPath: keyPath] = $0 }
		)
	}

	/// Booleans are stored as `"Yes"`/`"No"` strings. Binding a `Bool` over that keeps
	/// the checkbox honest about what the setting is without disturbing the stored
	/// representation or the `do…` readers that depend on it.
	private func yesNo(_ keyPath: ReferenceWritableKeyPath<Preferences, String>) -> Binding<Bool> {
		Binding(
			get: { preferences[keyPath: keyPath] == "Yes" },
			set: { preferences[keyPath: keyPath] = $0 ? "Yes" : "No" }
		)
	}

	/// The selected font is always offered, even when it is proportional and the
	/// monospaced filter is on. Dropping it would leave the picker with no row matching
	/// its tag, which renders blank — and silently rewriting the preference to fit the
	/// filter would lose a deliberate choice.
	private var fontOptions: [PreferenceOption] {
		let base = preferences.showsMonospacedFontsOnly ? Self.monospacedFonts : Self.allFonts
		let selected = preferences.font
		var names = base
		if !names.contains(selected) {
			let insertion = names.firstIndex { $0 > selected } ?? names.endIndex
			names.insert(selected, at: insertion)
		}
		return names.map { PreferenceOption(value: $0, label: $0) }
	}
}
