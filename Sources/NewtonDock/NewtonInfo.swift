
import Foundation


public struct NewtonInfo {

    public static func decode(data: Data) -> NewtonInfo {
        var data = data

        let count = MemoryLayout<NewtonInfo>.size / MemoryLayout<UInt32>.size
        data.withUnsafeMutableBytes { (p: UnsafeMutablePointer<UInt32>) in
            var p = p
            for _ in 0..<count {
                p.pointee = UInt32(bigEndian: p.pointee)
                p = p.successor()
            }
        }
        return data.withUnsafeBytes { (pointer: UnsafePointer<NewtonInfo>) in
            // TODO: unsure if memory needs to be rebound:
            // `UnsafeRawPointer(pointer).bindMemory(to: NewtonInfo.self, capacity: 1).pointee`
            pointer.pointee
        }
    }

    // A unique id to identify a particular newton
    public let newtonID: UInt32

    // A decimal integer indicating the manufacturer of the device
    private let manufacturerCode: UInt32

    private var manufacturer: GestaltManufacturer? {
        return GestaltManufacturer(rawValue: manufacturerCode)
    }

    // A decimal integer indicating the hardware type of the device
    private let machineTypeCode: UInt32

    private var machineType: GestaltMachineType? {
        return GestaltMachineType(rawValue: machineTypeCode)
    }

    // A decimal number indicating the major and minor ROM version numbers
    // The major number is in front of the decimal, the minor number after
    public let romVersion: UInt32

    // A decimal integer indicating the language (English, German, French)
    // and the stage of the ROM (alpha, beta, final)
    public let romStage: UInt32

    public let ramSize: UInt32

    // An integer representing the height of the screen in pixels
    public let screenHeight: UInt32

    // An integer representing the width of the screen in pixels
    public let screenWidth: UInt32

    // 0 on an unpatched Newton and nonzero on a patched Newton
    public let patchVersion: UInt32

    public let newtonOSVersion: UInt32

    // signature of the internal store
    public let internalStoreSignature: UInt32

    // An integer representing the number of vertical pixels per inch
    public let screenResolutionV: UInt32

    // An integer representing the number of horizontal pixels per inch
    public let screenResolutionH: UInt32

    // The bit depth of the LCD screen
    public let screenDepth: UInt32

    // various bit flags
    public let systemFlags: UInt32

    // TODO:
    private let serialNumber: UInt64

    public let targetProtocol: UInt32
}
