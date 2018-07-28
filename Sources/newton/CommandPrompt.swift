

import Foundation
import NewtonKit
import NewtonDock
import NSOF
import NewtonTranslators
import Html


final class CommandPrompt {

    private enum State {
        case idle
        case initiatingKeyboardPassthrough
        case keyboardPassthrough
        case initiatingBackup
        case backingUp
        case gettingInfo
        case loadingPackage
    }

    private enum Command: String {
        case keyboard
        case backup
        case info
        case load
    }

    private static func defaultBackupPath() throws -> String {
        var supportDirectoryURL =
            try FileManager.default.url(for: .applicationSupportDirectory,
                                        in: .userDomainMask,
                                        appropriateFor: nil,
                                        create: true)
        supportDirectoryURL.appendPathComponent("Newton", isDirectory: true)
        supportDirectoryURL.appendPathComponent("Backups", isDirectory: true)
        return supportDirectoryURL.path
    }

    private(set) var started = false

    private var state: State = .idle

    private let dockConnectionLayer: DockConnectionLayer
    private let backupPath: String

    init(dockConnectionLayer: DockConnectionLayer,
         backupPath: String? = nil) throws {

        self.dockConnectionLayer = dockConnectionLayer
        self.backupPath = try backupPath ?? CommandPrompt.defaultBackupPath()
        try createDirectory(path: self.backupPath)
        dockConnectionLayer.backupLayer.onEntry = handleBackupEntry
        dockConnectionLayer.onCallResult = onCallResult
        dockConnectionLayer.packageLayer.onResult = onPackageLoadingResult
    }

    private func createDirectory(path: String) throws {
        try FileManager.default.createDirectory(atPath: path,
                                                withIntermediateDirectories: true,
                                                attributes: nil)
    }

    private func prompt() -> String? {
        print("[\(state)] ? ", terminator: "")
        return readLine()
    }

    private func startKeyboardPassthrough() throws {
        let dockState = dockConnectionLayer.state
        guard dockState == .connected else {
            print("Can't connect in dock connection state: \(dockState)")
            return
        }

        state = .initiatingKeyboardPassthrough
        try dockConnectionLayer.startKeyboardPassthrough()
    }

    private func sendKeyboardString(_ line: String) throws {
        guard state == .keyboardPassthrough else {
            print("Can't send keyboard string in state: \(state)")
            return
        }

        try dockConnectionLayer.keyboardPassthroughLayer.sendString(line)
    }

    private func stopKeyboardPassthrough() throws {
        try dockConnectionLayer.keyboardPassthroughLayer.stop()
    }

    private func startBackup() throws {
        let dockState = dockConnectionLayer.state
        guard dockState == .connected else {
            print("Can't connect in dock connection state: \(dockState)")
            return
        }

        state = .initiatingBackup
        try dockConnectionLayer.startBackup()
    }

    private func getInfo() throws {
        let dockState = dockConnectionLayer.state
        guard dockState == .connected else {
            print("Can't connect in dock connection state: \(dockState)")
            return
        }

        state = .gettingInfo
        try dockConnectionLayer.callGlobalFunction(name: "Gestalt", arguments: [
            0x1000003 as NewtonInteger
        ])
    }

    private func loadPackage(atPath path: String) throws {
        let dockState = dockConnectionLayer.state
        guard dockState == .connected else {
            print("Can't connect in dock connection state: \(dockState)")
            return
        }

        guard let data = FileManager.default.contents(atPath: path) else {
            print("Can't load package at path: \(path)")
            return
        }

        state = .loadingPackage
        try dockConnectionLayer.loadPackage(data: data)
    }

    func handleDockConnectionState(state: DockConnectionLayer.State) {
        switch self.state {
        case .idle:
            if state == .keyboardPassthrough {
                print("keyboard passthrough active\n")
                self.state = .keyboardPassthrough
            }
        case .initiatingKeyboardPassthrough:
            if state == .keyboardPassthrough {
                print("keyboard passthrough active\n")
                self.state = .keyboardPassthrough
            }
        case .keyboardPassthrough:
            if state == .connected {
                print("stopped keyboard passthrough\n")
                self.state = .idle
            }
        case .initiatingBackup:
            if state == .backingUp {
                print("backup started\n")
                self.state = .backingUp
            }
        case .backingUp:
            if state == .connected {
                print("backup finished\n")
                self.state = .idle
            }
        case .gettingInfo:
            break
        case .loadingPackage:
            if state == .connected {
                print("package loading stopped")
                self.state = .idle
            }
            break
        }
    }

    func start() throws {
        started = true
        while let line = prompt() {
            guard !line.isEmpty else {
                continue
            }

            switch state {
            case .idle:
                let parts = line.split(separator: " ", maxSplits: 1)
                if let firstPart = parts.first,
                    let command = Command(rawValue: String(firstPart)) {

                    switch command {
                    case .keyboard:
                        try startKeyboardPassthrough()
                    case .backup:
                        try startBackup()
                    case .info:
                        try getInfo()
                    case .load:
                        guard parts.count > 1 else {
                            print("Missing path")
                            break
                        }
                        let path = String(parts[1])
                        try loadPackage(atPath: path)
                    }
                }
            case .keyboardPassthrough:
                if line == ".stop" {
                    try stopKeyboardPassthrough()
                } else {
                    try sendKeyboardString(line)
                }
            default:
                continue
            }
        }
    }

    private func backupFileURL(application: String, filename: String) throws -> URL {
        let applicationURL = URL(fileURLWithPath: backupPath)
            .appendingPathComponent(application, isDirectory: true)
        try createDirectory(path: applicationURL.path)
        return applicationURL.appendingPathComponent(filename)
    }

    private func handleBackupEntry(entry: NewtonFrame) throws {
        guard let uniqueID = (entry["_uniqueID"] as? NewtonInteger)
            .map({ String($0.integer) })
        else {
            print("Skipping entry without unique ID")
            return
        }

        if case "paperroll" as NewtonSymbol = entry["viewStationery"] {
            let document = translateToHTMLDocument(paperroll: entry)
            let html = render(document, config: pretty)
            let url = try backupFileURL(application: "Notes", filename: "\(uniqueID).html")
            try html.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    private func onCallResult(result: NewtonObject) {
        switch state {
        case .gettingInfo:
            print("Info:\n\(result)\n")
        default:
            print("Unexpected call result: \(result)")
        }

        state = .idle
    }

    private func onPackageLoadingResult(successful: Bool) {
        if successful {
            print("package loading finished")
        } else {
            print("package loading failed")
        }
        state = .idle
    }
}
