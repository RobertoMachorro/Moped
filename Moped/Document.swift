//
//  Document.swift
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

import Cocoa

class Document: NSDocument {

	@objc let model = TextFileModel(content: "", typeName: "public.plain-text", typeLanguage: "plaintext")

	override init() {
		super.init()
	}

	// MARK: - Enablers

	override class var autosavesInPlace: Bool {
		return true // FALSE: Enables Save As, disables versioning
	}

	override func canAsynchronouslyWrite(to url: URL, ofType typeName: String, for saveOperation: NSDocument.SaveOperationType) -> Bool {
		return true
	}

	override class func canConcurrentlyReadDocuments(ofType: String) -> Bool {
		return true
	}

	// MARK: - User Interface

	override func makeWindowControllers() {
		// Returns the Storyboard that contains your Document window.
		let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
		if let windowController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("Document Window Controller")) as? WindowController {
			self.addWindowController(windowController)

			if let viewController = windowController.contentViewController as? ViewController {
				viewController.representedObject = model
			}
		}
	}

	// MARK: - Reading and Writing

	override func read(from data: Data, ofType typeName: String) throws {
		// TODO: Switch to extension based recognitions
		/*
		if let fileExtension = self.fileURL?.pathExtension {
			NSLog("FILE EXTENSION: \(fileExtension)")
		}
		if let fileName = self.displayName {
			NSLog("FILE NAME: \(fileName)")
		}
		*/
		model.read(from: data, ofType: typeName)
	}

	override func data(ofType typeName: String) throws -> Data {
		// TODO: Switch to extension based recognitions
		/*
		if let fileExtension = self.fileURL?.pathExtension {
			NSLog("FILE EXTENSION: \(fileExtension)")
		}
		if let fileName = self.displayName {
			NSLog("FILE NAME: \(fileName)")
		}
		*/
		return model.data(ofType: typeName)!
	}

	// MARK: - Printing

	func thePrintInfo() -> NSPrintInfo {
		let thePrintInfo = NSPrintInfo()
		thePrintInfo.horizontalPagination = .fit
		thePrintInfo.isHorizontallyCentered = false
		thePrintInfo.isVerticallyCentered = false
		
		// One inch margin all the way around.
		thePrintInfo.leftMargin = 72.0
		thePrintInfo.rightMargin = 72.0
		thePrintInfo.topMargin = 72.0
		thePrintInfo.bottomMargin = 72.0

		printInfo.dictionary().setObject(NSNumber(value: true), forKey: NSPrintInfo.AttributeKey.headerAndFooter as NSCopying)
		
		return thePrintInfo
	}

	@objc func printOperationDidRun(_ printOperation: NSPrintOperation, success: Bool, contextInfo: UnsafeMutableRawPointer?) {
		// Printing finished...
	}

	@IBAction override func printDocument(_ sender: Any?) {
		// Print the NSTextView.

		// Create a copy to manipulate for printing.
		let pageSize = NSSize(width: (printInfo.paperSize.width), height: (printInfo.paperSize.height))
		let textView = NSTextView(frame: NSRect(x: 0.0, y: 0.0, width: pageSize.width, height: pageSize.height))

		// Make sure we print on a white background.
		textView.appearance = NSAppearance(named: .aqua)

		// Copy the attributed string.
		textView.textStorage?.append(NSAttributedString(string: model.content))

		let printOperation = NSPrintOperation(view: textView)
		printOperation.runModal(for: windowControllers[0].window!, delegate: self, didRun: #selector(printOperationDidRun(_:success:contextInfo:)), contextInfo: nil)
	}

}
