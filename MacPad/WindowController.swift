//
//  WindowController.swift
//  MacPad
//
//  Created by Roberto Machorro on 8/9/19.
//  Copyright © 2019 Unplugged Ideas, LLC. All rights reserved.
//

import Cocoa

class WindowController: NSWindowController {

	required init?(coder: NSCoder) {
		super.init(coder: coder)
		shouldCascadeWindows = true
	}

	override func windowDidLoad() {
		super.windowDidLoad()
	}

}
