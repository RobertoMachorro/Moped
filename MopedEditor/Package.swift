// swift-tools-version: 5.9

//
//  Package.swift
//
//  MopedEditor - The homegrown text editor core and syntax highlighter used by Moped.
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

import PackageDescription

let strictConcurrency: [SwiftSetting] = [.enableExperimentalFeature("StrictConcurrency")]

let package = Package(
	name: "MopedEditor",
	platforms: [
		.macOS(.v14)
	],
	products: [
		.library(name: "MopedEditor", targets: ["MopedEditor"])
	],
	targets: [
		// The app target builds these sources with SWIFT_STRICT_CONCURRENCY = complete, so
		// the package has to ask for the same checking or `swift test` — the gate CI runs —
		// would compile them under looser rules than Xcode does. It matters more than usual
		// here because this package is meant to be extractable, and these settings are what
		// would follow it out.
		.target(name: "MopedEditor", swiftSettings: strictConcurrency),
		.testTarget(
			name: "MopedEditorTests",
			dependencies: ["MopedEditor"],
			swiftSettings: strictConcurrency
		)
	]
)
