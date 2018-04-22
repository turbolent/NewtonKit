
import Foundation

extension Data {
    
    public var hexLine: String {
        return map { String(format: "%02x", $0) }
            .joined(separator: " ")
    }

    public var hexDump: String {
        let subChunkWidth = 8
        let chunkWidth = subChunkWidth * 2

        func pad(_ subChunk: String) -> String {
            return subChunk.padding(toLength: subChunkWidth * 3 - 1,
                                    withPad: " ",
                                    startingAt: 0)
        }
        return chunk(n: chunkWidth)
            .enumerated()
            .map { offset, chunkData in
                let offsetFormatted = String(format: "%08x", offset * chunkWidth)
                let subChunks = chunkData.chunk(n: subChunkWidth)
                let subChunk1Formatted =
                    pad(subChunks[0].hexLine)
                let subChunk2Formatted =
                    pad(subChunks.count > 1 ? subChunks[1].hexLine : "")
                let humanReadable =
                    String(format: "|%@|", chunkData.map {
                        return 32..<126 ~= $0 ? String(UnicodeScalar($0)) : "."
                        }.joined())
                return [
                    offsetFormatted,
                    subChunk1Formatted,
                    subChunk2Formatted,
                    humanReadable
                    ].joined(separator: "  ")
            }
            .joined(separator: "\n")
    }
}
