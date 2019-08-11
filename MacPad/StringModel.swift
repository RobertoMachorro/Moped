//
//  StringModel.swift
//  MacPad
//
//  Created by Roberto Machorro on 8/11/19.
//  Copyright © 2019 Roberto Machorro. All rights reserved.
//

import Foundation

class StringModel: NSObject {

	@objc dynamic var textString = ""

	public init(textString: String) {
		self.textString = textString
	}

}

extension StringModel {

	func read(from data: Data) {
		textString = String(data: data, encoding: .utf8)!
	}

	func data() -> Data? {
		return textString.data(using: .utf8)
	}

}
