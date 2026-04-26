//
//  DefaultEditorSelectorView.swift
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

import Cocoa
import SwiftUI
import UniformTypeIdentifiers

struct DefaultEditorItem: Identifiable {
	let id: String
	let utType: UTType
	let extensions: [String]
	let description: String
	let currentAppURL: URL?
	let currentAppName: String
	let currentAppIcon: NSImage?
	let isMopedAlready: Bool
	var isSelected: Bool
}

@MainActor
final class DefaultEditorSelectorModel: ObservableObject {
	@Published var items: [DefaultEditorItem] = []
	@Published var isLoading = true
	@Published var isApplying = false
	@Published var searchText = ""

	private let mopedBundleURL: URL = Bundle.main.bundleURL
	private let mopedBundleID: String = Bundle.main.bundleIdentifier ?? ""

	init() {
		Task {
			await loadItems()
		}
	}

	private func loadItems() async {
		let types = MopedDocument.readableContentTypes
		let mopedURL = mopedBundleURL
		let mopedID = mopedBundleID

		let loaded: [DefaultEditorItem] = await Task.detached(priority: .userInitiated) {
			var result: [DefaultEditorItem] = []
			for utType in types {
				let extensions = utType.tags[UTTagClass.filenameExtension] ?? []
				guard !extensions.isEmpty else { continue }

				let description = utType.localizedDescription ?? utType.identifier
				let currentAppURL = NSWorkspace.shared.urlForApplication(toOpen: utType)
				let currentAppName: String
				let currentAppIcon: NSImage?

				if let appURL = currentAppURL {
					currentAppName = Bundle(url: appURL)?.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
						?? Bundle(url: appURL)?.object(forInfoDictionaryKey: "CFBundleName") as? String
						?? appURL.deletingPathExtension().lastPathComponent
					currentAppIcon = NSWorkspace.shared.icon(forFile: appURL.path)
				} else {
					currentAppName = String(localized: "default_editor.no_app")
					currentAppIcon = nil
				}

				let currentBundleID = currentAppURL.flatMap {
					Bundle(url: $0)?.bundleIdentifier
				} ?? ""
				let isMopedAlready = currentBundleID == mopedID || currentAppURL == mopedURL

				let currentIsTextEdit = currentBundleID == "com.apple.TextEdit"
				let isUnassigned = currentAppURL == nil

				let item = DefaultEditorItem(
					id: utType.identifier,
					utType: utType,
					extensions: extensions.sorted(),
					description: description,
					currentAppURL: currentAppURL,
					currentAppName: currentAppName,
					currentAppIcon: currentAppIcon,
					isMopedAlready: isMopedAlready,
					isSelected: !isMopedAlready && (currentIsTextEdit || isUnassigned)
				)
				result.append(item)
			}
			return result.sorted { $0.description.lowercased() < $1.description.lowercased() }
		}.value

		items = loaded
		isLoading = false
	}

	var filteredIndices: [Int] {
		if searchText.isEmpty {
			return Array(items.indices)
		}
		let query = searchText.lowercased()
		return items.indices.filter { i in
			let item = items[i]
			return item.description.lowercased().contains(query)
				|| item.extensions.joined(separator: " ").lowercased().contains(query)
				|| item.currentAppName.lowercased().contains(query)
		}
	}

	var selectedCount: Int {
		items.filter { $0.isSelected }.count
	}

	func selectAll() {
		for i in items.indices where !items[i].isMopedAlready {
			items[i].isSelected = true
		}
	}

	func selectTextEdit() {
		for i in items.indices {
			guard !items[i].isMopedAlready else { continue }
			let bundleID = items[i].currentAppURL.flatMap {
				Bundle(url: $0)?.bundleIdentifier
			} ?? ""
			items[i].isSelected = bundleID == "com.apple.TextEdit"
		}
	}

	func selectNone() {
		for i in items.indices {
			items[i].isSelected = false
		}
	}

	func applySelections(completion: @escaping () -> Void) {
		let selected = items.filter { $0.isSelected }.map { $0.utType }
		guard !selected.isEmpty else {
			completion()
			return
		}

		isApplying = true
		let appURL = mopedBundleURL
		let group = DispatchGroup()
		for utType in selected {
			group.enter()
			NSWorkspace.shared.setDefaultApplication(at: appURL, toOpen: utType) { _ in
				group.leave()
			}
		}
		group.notify(queue: .main) { [weak self] in
			self?.isApplying = false
			Task { @MainActor [weak self] in
				await self?.loadItems()
			}
			completion()
		}
	}
}

struct DefaultEditorSelectorView: View {
	@StateObject private var model = DefaultEditorSelectorModel()
	var onClose: (() -> Void)?

	var body: some View {
		VStack(spacing: 0) {
			sandboxWarning
			Divider()
			headerBar

			if model.isLoading {
				Spacer()
				ProgressView(String(localized: "default_editor.loading"))
				Spacer()
			} else {
				itemList
			}

			Divider()
			bottomBar
		}
		.frame(width: 560, height: 480)
	}

	private var sandboxWarning: some View {
		HStack(spacing: 8) {
			Image(systemName: "exclamationmark.triangle.fill")
				.foregroundStyle(.yellow)
			Text("default_editor.sandbox_warning")
				.font(.caption)
				.foregroundStyle(.secondary)
			Spacer()
		}
		.padding(.horizontal, 16)
		.padding(.vertical, 8)
		.background(.yellow.opacity(0.08))
	}

	private var headerBar: some View {
		VStack(spacing: 8) {
			HStack {
				Text("default_editor.subtitle")
					.font(.subheadline)
					.foregroundStyle(.secondary)
				Spacer()
				HStack(spacing: 4) {
					Button(String(localized: "default_editor.select_all")) { model.selectAll() }
						.buttonStyle(.borderless)
					Text("·").foregroundStyle(.secondary)
					Button(String(localized: "default_editor.select_textedit")) { model.selectTextEdit() }
						.buttonStyle(.borderless)
					Text("·").foregroundStyle(.secondary)
					Button(String(localized: "default_editor.select_none")) { model.selectNone() }
						.buttonStyle(.borderless)
				}
				.font(.subheadline)
			}
			TextField(String(localized: "default_editor.search_placeholder"), text: $model.searchText)
				.textFieldStyle(.roundedBorder)
		}
		.padding(.horizontal, 16)
		.padding(.top, 12)
		.padding(.bottom, 8)
	}

	private var itemList: some View {
		List {
			ForEach(model.filteredIndices, id: \.self) { i in
				itemRow(index: i)
					.listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
			}
		}
		.listStyle(.inset)
	}

	private func itemRow(index i: Int) -> some View {
		HStack(spacing: 10) {
			Toggle("", isOn: $model.items[i].isSelected)
				.labelsHidden()
				.disabled(model.items[i].isMopedAlready)

			VStack(alignment: .leading, spacing: 2) {
				Text(model.items[i].description)
					.font(.body)
				Text(model.items[i].extensions.map { ".\($0)" }.joined(separator: "  "))
					.font(.caption)
					.foregroundStyle(.secondary)
			}
			.frame(maxWidth: .infinity, alignment: .leading)

			HStack(spacing: 6) {
				if let icon = model.items[i].currentAppIcon {
					Image(nsImage: icon)
						.resizable()
						.frame(width: 20, height: 20)
				}
				Text(model.items[i].isMopedAlready
					? String(localized: "default_editor.already_moped")
					: model.items[i].currentAppName)
					.font(.caption)
					.foregroundStyle(model.items[i].isMopedAlready ? .secondary : .primary)
					.frame(width: 140, alignment: .trailing)
			}
		}
	}

	private var bottomBar: some View {
		HStack {
			Text(
				model.selectedCount == 0
					? String(localized: "default_editor.none_selected")
					: String(format: String(localized: "default_editor.n_selected"), model.selectedCount)
			)
			.font(.subheadline)
			.foregroundStyle(.secondary)

			Spacer()

			Button(String(localized: "default_editor.cancel")) {
				onClose?()
			}
			.keyboardShortcut(.cancelAction)

			Button(
				model.isApplying
					? String(localized: "default_editor.applying")
					: String(
						format: String(localized: "default_editor.apply_button"),
						model.selectedCount
					)
			) {
				model.applySelections {
					onClose?()
				}
			}
			.keyboardShortcut(.defaultAction)
			.disabled(model.selectedCount == 0 || model.isApplying)
		}
		.padding(.horizontal, 16)
		.padding(.vertical, 10)
	}
}
