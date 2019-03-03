import XCTest

import NewtonTranslatorsTests
import MNPTests
import NSOFTests
import NewtonDockTests

var tests = [XCTestCaseEntry]()
tests += NewtonTranslatorsTests.__allTests()
tests += MNPTests.__allTests()
tests += NSOFTests.__allTests()
tests += NewtonDockTests.__allTests()

XCTMain(tests)
