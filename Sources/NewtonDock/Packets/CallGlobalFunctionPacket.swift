

import Foundation
import NSOF


public struct CallGlobalFunctionPacket: EncodableDockPacket {

    public static let command: DockCommand = .callGlobalFunction

    public let name: NewtonSymbol
    public let arguments: NewtonPlainArray

    public init(name: NewtonSymbol, arguments: NewtonPlainArray) {
        self.name = name
        self.arguments = arguments
    }

    public func encode() -> Data? {
        var data = Data()
        data.append(NewtonObjectEncoder.encodeRoot(newtonObject: name))
        data.append(NewtonObjectEncoder.encodeRoot(newtonObject: arguments))
        return data
    }
}

