
public struct DockIconMask: OptionSet {

    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public static let backup = DockIconMask(rawValue: 1 << 0)
    public static let restore = DockIconMask(rawValue: 1 << 1)
    public static let install = DockIconMask(rawValue: 1 << 2)
    public static let `import` = DockIconMask(rawValue: 1 << 3)
    public static let sync = DockIconMask(rawValue: 1 << 4)
    public static let keyboard = DockIconMask(rawValue: 1 << 5)

    public static let all: DockIconMask = [
        .backup, .restore, .install, .`import`, .sync, .keyboard
    ]
}
