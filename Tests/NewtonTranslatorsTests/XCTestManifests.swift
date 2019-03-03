import XCTest

extension DocumentTranslatorTests {
    static let __allTests = [
        ("testDocumentTranslator", testDocumentTranslator),
    ]
}

extension EventTranslatorTests {
    static let __allTests = [
        ("testEventTranslator", testEventTranslator),
    ]
}

extension NewtonPackageTests {
    static let __allTests = [
        ("testInvalidSignature", testInvalidSignature),
        ("testParsePackage1", testParsePackage1),
        ("testParsePackage2", testParsePackage2),
        ("testTooShort", testTooShort),
    ]
}

#if !os(macOS)
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(DocumentTranslatorTests.__allTests),
        testCase(EventTranslatorTests.__allTests),
        testCase(NewtonPackageTests.__allTests),
    ]
}
#endif
