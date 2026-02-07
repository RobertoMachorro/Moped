//
//  AboutView.swift
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

import SwiftUI

struct AboutView: View {
	private let infoText = """
	A general purpose text editor, small and light.
	Copyright (C) 2019-2026 Roberto Machorro. All rights reserved.

	This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

	This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
	"""

	private var versionString: String {
		let versionNumber = Bundle.main.object(
			forInfoDictionaryKey: "CFBundleShortVersionString"
		) as? String ?? "?"
		let buildNumber = Bundle.main.object(
			forInfoDictionaryKey: "CFBundleVersion"
		) as? String ?? "?"
		return "v\(versionNumber) (\(buildNumber))"
	}

	var body: some View {
		VStack(alignment: .leading, spacing: 12) {
			HStack(alignment: .top) {
				VStack(spacing: 6) {
					Text("Moped")
						.font(.system(size: 16, weight: .bold))
					Text(versionString)
						.font(.system(size: 12))
				}
				.frame(maxWidth: .infinity)

				Image("Logo")
					.resizable()
					.frame(width: 64, height: 64)
			}

			Text(infoText)
				.font(.system(size: 9))
				.multilineTextAlignment(.leading)
				.frame(maxWidth: .infinity, alignment: .leading)

			Spacer()
		}
		.padding(20)
		.frame(width: 340, height: 250, alignment: .topLeading)
	}
}
