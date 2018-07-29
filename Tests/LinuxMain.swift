import XCTest
@testable import NewtonDockTests
@testable import MNPTests
@testable import NSOFTests
@testable import NewtonTranslatorsTests

XCTMain([
    testCase(NewtonDockTests.allTests),
    testCase(MNPTests.allTests),
    testCase(NSOFTests.allTests),
    testCase(HTMLTranslatorTests.allTests),
    testCase(NewtonPackageTests.allTests),
])
