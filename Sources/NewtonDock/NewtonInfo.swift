
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

    public init(
        newtonID: UInt32,
        manufacturerCode: UInt32,
        machineTypeCode: UInt32,
        romVersion: UInt32,
        romStage: UInt32,
        ramSize: UInt32,
        screenHeight: UInt32,
        screenWidth: UInt32,
        patchVersion: UInt32,
        newtonOSVersion: UInt32,
        internalStoreSignature: UInt32,
        screenResolutionV: UInt32,
        screenResolutionH: UInt32,
        screenDepth: UInt32,
        systemFlags: UInt32,
        serialNumber: UInt64,
        targetProtocol: UInt32
    ) {
        self.newtonID = newtonID
        self.manufacturerCode = manufacturerCode
        self.machineTypeCode = machineTypeCode
        self.romVersion = romVersion
        self.romStage = romStage
        self.ramSize = ramSize
        self.screenHeight = screenHeight
        self.screenWidth = screenWidth
        self.patchVersion = patchVersion
        self.newtonOSVersion = newtonOSVersion
        self.internalStoreSignature = internalStoreSignature
        self.screenResolutionV = screenResolutionV
        self.screenResolutionH = screenResolutionH
        self.screenDepth = screenDepth
        self.systemFlags = systemFlags
        self.serialNumber = serialNumber
        self.targetProtocol = targetProtocol
    }

    /// A unique id to identify a particular newton
    public let newtonID: UInt32

    /// A decimal integer indicating the manufacturer of the device
    public let manufacturerCode: UInt32

    public var manufacturer: GestaltManufacturer? {
        return GestaltManufacturer(rawValue: manufacturerCode)
    }

    /// A decimal integer indicating the hardware type of the device
    public let machineTypeCode: UInt32

    /// The hardware type of the device
    public var machineType: GestaltMachineType? {
        return GestaltMachineType(rawValue: machineTypeCode)
    }

    /// A decimal number indicating the major and minor ROM version numbers
    /// The major number is in front of the decimal, the minor number after
    public let romVersion: UInt32

    /// A decimal integer indicating the language (English, German, French)
    /// and the stage of the ROM (alpha, beta, final)
    public let romStage: UInt32

    public let ramSize: UInt32

    /// An integer representing the height of the screen in pixels
    public let screenHeight: UInt32

    /// An integer representing the width of the screen in pixels
    public let screenWidth: UInt32

    /// 0 on an unpatched Newton and nonzero on a patched Newton
    public let patchVersion: UInt32

    public let newtonOSVersion: UInt32

    /// signature of the internal store
    public let internalStoreSignature: UInt32

    /// An integer representing the number of vertical pixels per inch
    public let screenResolutionV: UInt32

    /// An integer representing the number of horizontal pixels per inch
    public let screenResolutionH: UInt32

    /// The bit depth of the LCD screen
    public let screenDepth: UInt32

    /// various bit flags
    public let systemFlags: UInt32

    public let serialNumber: UInt64

    public let targetProtocol: UInt32
}
