
#if os(macOS)

import Foundation
import IOKit
import IOKit.serial

internal let serialPortMatching: CFDictionary = {
    let matching = IOServiceMatching(kIOSerialBSDServiceValue) as NSMutableDictionary
    matching[kIOSerialBSDTypeKey] = kIOSerialBSDRS232Type
    return matching
}()

#endif
