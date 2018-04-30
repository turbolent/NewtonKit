import XCTest
@testable import NewtonDockTests
@testable import MNPTests
@testable import NSOFTests

XCTMain([
    testCase(NewtonDockTests.allTests),
    testCase(MNPTests.allTests),
    testCase(NSOFTests.allTests),
])
