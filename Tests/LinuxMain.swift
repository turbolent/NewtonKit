import XCTest

import MNPTests
import NSOFTests
import NewtonDockTests
import NewtonTranslatorsTests

var tests = [XCTestCaseEntry]()
tests += MNPTests.__allTests()
tests += NSOFTests.__allTests()
tests += NewtonDockTests.__allTests()
tests += NewtonTranslatorsTests.__allTests()

XCTMain(tests)
