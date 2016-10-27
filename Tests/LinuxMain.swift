import XCTest
@testable import Silica

#if os(OSX) || os(iOS) || os(watchOS)
	func XCTMain(_ testCases: [XCTestCaseEntry]) { fatalError("Not Implemented. Linux only") }
	
	func testCase<T: XCTestCase>(_ allTests: [(String, (T) -> () throws -> Void)]) -> XCTestCaseEntry { fatalError("Not Implemented. Linux only") }
	
	struct XCTestCaseEntry { }
#endif

XCTMain([
     testCase(SilicaTests.allTests),
])
