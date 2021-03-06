#if !canImport(ObjectiveC)
import XCTest

extension DocumentTranslatorTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__DocumentTranslatorTests = [
        ("testDocumentTranslator", testDocumentTranslator),
    ]
}

extension EventTranslatorTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__EventTranslatorTests = [
        ("testEventTranslator", testEventTranslator),
    ]
}

extension NewtonPackageTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__NewtonPackageTests = [
        ("testInvalidSignature", testInvalidSignature),
        ("testParsePackage1", testParsePackage1),
        ("testParsePackage2", testParsePackage2),
        ("testTooShort", testTooShort),
    ]
}

public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(DocumentTranslatorTests.__allTests__DocumentTranslatorTests),
        testCase(EventTranslatorTests.__allTests__EventTranslatorTests),
        testCase(NewtonPackageTests.__allTests__NewtonPackageTests),
    ]
}
#endif
