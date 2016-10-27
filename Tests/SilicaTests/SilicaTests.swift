//
//  FontTests.swift
//  Silica
//
//  Created by Alsey Coleman Miller on 6/1/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

import XCTest
@testable import Silica
import Cairo

class SilicaTests: XCTestCase {

	func testCreateSimpleFont() {
		
		guard let font = Font(name: "Arial")
			else { XCTFail("Could not create font"); return }
		
		let expectedFullName = "Arial"
		
		XCTAssert(font.name == font.name)
		XCTAssert(expectedFullName == font.scaledFont.fullName, "\(expectedFullName) == \(font.scaledFont.fullName)")
	}
	
	func testCreateTraitFont() {
		
		guard let font = Font(name: "Arial-Bold")
			else { XCTFail("Could not create font"); return }
		
		let expectedFullName = "Arial"
		
		XCTAssert(font.name == font.name)
		XCTAssert(expectedFullName == font.scaledFont.fullName, "\(expectedFullName) == \(font.scaledFont.fullName)")
	}



    static var allTests : [(String, (SilicaTests) -> () throws -> Void)] {
        return [
            ("testCreateSimpleFont", testCreateSimpleFont),
            ("testCreateTraitFont", testCreateTraitFont)
        ]
    }
}
