//
//  LoggingCodeAttributedString.swift
//
//  Moped - A general purpose text editor, small and light.
//
//  Debug helper to verify Highlightr's CodeAttributedString receives edits.
//

import Foundation
import Highlightr

final class LoggingCodeAttributedString: CodeAttributedString {
	override func processEditing() {
		print("[Moped][Highlightr] processEditing editedRange=\(editedRange) changeInLength=\(changeInLength)")
		super.processEditing()
	}
}
