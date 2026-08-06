//
//  ContentKindTests.swift
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

import XCTest
@testable import MopedEditor

final class ContentKindTests: XCTestCase {
	// MARK: Text that must keep opening

	func testPlainText() {
		XCTAssertEqual(ContentKind.of(Data("hello world\n".utf8)), .text)
		XCTAssertEqual(ContentKind.of(Data("let a = 1\nlet b = 2\n".utf8)), .text)
	}

	func testEmptyFileIsText() {
		XCTAssertEqual(ContentKind.of(Data()), .text, "a new empty document must open")
	}

	func testNonASCIIText() {
		XCTAssertEqual(ContentKind.of(Data("日本語テキスト\n".utf8)), .text)
		XCTAssertEqual(ContentKind.of(Data("émoji 🛵 accents\n".utf8)), .text)
	}

	func testUTF8BOMIsText() {
		XCTAssertEqual(ContentKind.of(Data([0xEF, 0xBB, 0xBF]) + Data("hi\n".utf8)), .text)
	}

	/// UTF-16/32 pad ASCII with NUL bytes, so without the BOM exemption these would
	/// read as binary.
	func testWideEncodingsWithBOMAreText() {
		let body = "hello\nworld\n"
		XCTAssertEqual(
			ContentKind.of(Data([0xFF, 0xFE]) + body.data(using: .utf16LittleEndian)!), .text,
			"UTF-16 LE with BOM"
		)
		XCTAssertEqual(
			ContentKind.of(Data([0xFE, 0xFF]) + body.data(using: .utf16BigEndian)!), .text,
			"UTF-16 BE with BOM"
		)
		XCTAssertEqual(
			ContentKind.of(Data([0xFF, 0xFE, 0x00, 0x00]) + body.data(using: .utf32LittleEndian)!), .text,
			"UTF-32 LE with BOM"
		)
		XCTAssertEqual(
			ContentKind.of(Data([0x00, 0x00, 0xFE, 0xFF]) + body.data(using: .utf32BigEndian)!), .text,
			"UTF-32 BE with BOM"
		)
	}

	/// Tabs, newlines, and carriage returns are control bytes but obviously text.
	func testWhitespaceHeavyTextIsNotBinary() {
		XCTAssertEqual(ContentKind.of(Data(String(repeating: "\t\r\n", count: 500).utf8)), .text)
	}

	// MARK: Binary that must be refused

	func testNulByteMeansBinary() {
		XCTAssertEqual(ContentKind.of(Data([0x00])), .binary)
		XCTAssertEqual(ContentKind.of(Data("text".utf8) + Data([0x00]) + Data("more".utf8)), .binary)
	}

	func testControlByteHeavyDataIsBinary() {
		// No NUL anywhere, but dense with control bytes — the secondary check.
		let payload = Data((0..<600).map { UInt8($0 % 0x08 + 0x01) })
		XCTAssertFalse(payload.contains(0), "fixture must not rely on the NUL scan")
		XCTAssertEqual(ContentKind.of(payload), .binary)
	}

	/// A synthesized Mach-O header shape rather than a read of `/bin/ls`, so the test
	/// doesn't depend on the machine it runs on: the 64-bit magic, load-command
	/// fields full of NUL bytes, and stretches of zero padding — the byte pattern the
	/// sniffer actually sees at the head of a real executable.
	func testMachOShapedBinaryIsRefused() {
		var data = Data([0xCF, 0xFA, 0xED, 0xFE])
		data += Data(repeating: 0x00, count: 512)
		data += Data("some embedded strings survive".utf8)
		data += Data(repeating: 0x00, count: 512)
		XCTAssertEqual(ContentKind.of(data), .binary, "a Mach-O executable must not open")
	}

	// MARK: Documented limits

	/// Only the first 8 KB are inspected, so a NUL past the window is missed. This is
	/// a deliberate trade, not an oversight — asserting it keeps the choice visible.
	func testNulPastInspectionWindowIsNotDetected() {
		let head = Data(repeating: 0x41, count: ContentKind.inspectionWindow)
		XCTAssertEqual(ContentKind.of(head + Data([0x00])), .text)

		let justInside = Data(repeating: 0x41, count: ContentKind.inspectionWindow - 1)
		XCTAssertEqual(ContentKind.of(justInside + Data([0x00])), .binary)
	}

	// MARK: BOM-less UTF-16

	/// Previously refused as binary, which is a confusing thing to be told about an
	/// ordinary text file. The NULs such a file contains all land on one parity of byte
	/// offset, which is what separates it from a binary.
	func testBOMlessUTF16IsText() {
		let littleEndian = "hello\nworld\n".data(using: .utf16LittleEndian)!
		XCTAssertEqual(ContentKind.of(littleEndian), .text)
		XCTAssertEqual(ContentKind.unmarkedWideEncoding(of: littleEndian), .utf16LittleEndian)

		let bigEndian = "hello\nworld\n".data(using: .utf16BigEndian)!
		XCTAssertEqual(ContentKind.of(bigEndian), .text)
		XCTAssertEqual(ContentKind.unmarkedWideEncoding(of: bigEndian), .utf16BigEndian)
	}

	/// The detected encoding has to be the one that actually decodes the bytes, or the
	/// caller trades a wrong refusal for silent mojibake.
	func testBOMlessUTF16RoundTripsThroughTheReportedEncoding() {
		for encoding in [String.Encoding.utf16LittleEndian, .utf16BigEndian] {
			let original = "let x = 1\nlet y = 2\n"
			let data = original.data(using: encoding)!
			guard let wide = ContentKind.unmarkedWideEncoding(of: data) else {
				return XCTFail("\(encoding) was not detected")
			}
			XCTAssertEqual(String(data: data, encoding: wide.stringEncoding), original)
		}
	}

	func testBinaryIsStillRefusedAfterTheWideCheck() {
		// NULs on both parities — the shape of real binary data, not of UTF-16.
		var mixed = Data()
		for index in 0..<512 {
			mixed.append(index % 3 == 0 ? 0x00 : UInt8(index % 251 + 1))
		}
		XCTAssertNil(ContentKind.unmarkedWideEncoding(of: mixed))
		XCTAssertEqual(ContentKind.of(mixed), .binary)

		// A NUL-padded binary whose zeros happen to share a parity but which is mostly
		// control bytes is still not text.
		let sparse = Data((0..<512).map { $0 % 2 == 1 ? 0x00 : UInt8(0x01) })
		XCTAssertEqual(ContentKind.of(sparse), .binary, "control-byte heavy data is not UTF-16")
	}

	func testTooLittleDataIsNotClaimedAsWide() {
		XCTAssertNil(ContentKind.unmarkedWideEncoding(of: Data([0x41, 0x00])))
		// An odd byte count cannot be UTF-16.
		XCTAssertNil(ContentKind.unmarkedWideEncoding(of: Data([0x41, 0x00, 0x42, 0x00, 0x43])))
	}

	func testASCIITextIsNotClaimedAsWide() {
		XCTAssertNil(ContentKind.unmarkedWideEncoding(of: Data("plain ascii text\n".utf8)))
	}
}
