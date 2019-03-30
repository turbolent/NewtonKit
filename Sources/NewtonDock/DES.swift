
import Foundation


/// Used in the key schedule to select 56 bits from a 64-bit input

private let permutedChoice1: [UInt8] = [
    7, 15, 23, 31, 39, 47, 55, 63,
    6, 14, 22, 30, 38, 46, 54, 62,
    5, 13, 21, 29, 37, 45, 53, 61,
    4, 12, 20, 28, 1, 9, 17, 25,
    33, 41, 49, 57, 2, 10, 18, 26,
    34, 42, 50, 58, 3, 11, 19, 27,
    35, 43, 51, 59, 36, 44, 52, 60,
]


/// Used in the key schedule to produce each subkey by selecting 48 bits from the 56-bit input

private let permutedChoice2: [UInt8] = [
    42, 39, 45, 32, 55, 51, 53, 28,
    41, 50, 35, 46, 33, 37, 44, 52,
    30, 48, 40, 49, 29, 36, 43, 54,
    15, 4, 25, 19, 9, 1, 26, 16,
    5, 11, 23, 8, 12, 7, 17, 0,
    22, 3, 10, 14, 6, 20, 27, 24,
]


private func permuteBlock(source: UInt64, permutation: [UInt8]) -> UInt64 {
    var result = 0 as UInt64
    let x = permutation.count - 1
    for (position, n) in permutation.enumerated() {
        let bit = (source >> n) & 1
        result |= bit << UInt(x - position)
    }
    return result
}

public enum DESError: Error {
    case invalidKeySize
}


/// Size of left rotation per round in each half of the key schedule

private let ksRotations: [UInt8] =
    [1, 1, 2, 2, 2, 2, 2, 2, 1, 2, 2, 2, 2, 2, 2, 1]


/// creates 16 28-bit blocks rotated according to the rotation schedule

private func ksRotate(_ value: UInt32) -> [UInt32] {
    var out = [UInt32](repeating: 0, count: 16)
    var last = value
    for i: Int in 0..<16 {
        // 28-bit circular left shift
        let t1 = ksRotations[i]
        let t2 = 4 + t1
        let t3 = last << t2
        let left = t3 >> 4

        let t4 = last << 4
        let t5 = ksRotations[i]
        let t6 = 32 - t5
        let right = t4 >> t6
        out[i] = left | right
        last = out[i]
    }
    return out
}


/// Expand 48-bit input to 64-bit, with each 6-bit block padded by extra two bits at the top.
/// By doing so, we can have the input blocks (four bits each), and the key blocks (six bits each)
/// well-aligned without extra shifts/rotations for alignments.

private func unpack(_ x: UInt64) -> UInt64 {
    let y1 = ((x >> (6 * 1) as UInt64) & 0xff) << (8 * 0)
    let y2 = ((x >> (6 * 3) as UInt64) & 0xff) << (8 * 1)
    let y3 = ((x >> (6 * 5) as UInt64) & 0xff) << (8 * 2)
    let y4 = ((x >> (6 * 7) as UInt64) & 0xff) << (8 * 3)
    let y5 = ((x >> (6 * 0) as UInt64) & 0xff) << (8 * 4)
    let y6 = ((x >> (6 * 2) as UInt64) & 0xff) << (8 * 5)
    let y7 = ((x >> (6 * 4) as UInt64) & 0xff) << (8 * 6)
    let y8 = ((x >> (6 * 6) as UInt64) & 0xff) << (8 * 7)
    return y1 | y2 | y3 | y4 | y5 | y6 | y7 | y8
}


/// creates 16 56-bit subkeys from the original key

private func generateSubkeys(_ keyBytes: [UInt8]) throws -> [UInt64] {

    guard let key = UInt64(bigEndianData: Data(keyBytes)) else {
        throw DESError.invalidKeySize
    }

    // apply PC1 permutation to key
    let permutedKey = permuteBlock(source: key, permutation: permutedChoice1)

    // rotate halves of permuted key according to the rotation schedule
    let leftRotations = ksRotate(UInt32(truncatingIfNeeded: permutedKey >> 28))
    let rightRotations = ksRotate(UInt32(truncatingIfNeeded: permutedKey << 4) >> 4)

    // generate subkeys
    return (0..<16).map { (offset: Int) in
        // combine halves to form 56-bit input to PC2
        let t1 = UInt64(leftRotations[offset]) << 28
        let t2 = UInt64(rightRotations[offset])
        let pc2Input: UInt64 = t1 | t2
        // apply PC2 permutation to 7 byte input
        return unpack(permuteBlock(source: pc2Input, permutation: permutedChoice2))
    }
}

private func cryptBlock(subkeys: [UInt64], source: Data, decrypt: Bool) -> Data? {

    guard var b = UInt64(bigEndianData: source) else {
        return nil
    }
    b = permuteInitialBlock(block: b)

    var left = UInt32(b >> 32)
    var right = UInt32(truncatingIfNeeded: b)

    left = (left << 1) | (left >> 31)
    right = (right << 1) | (right >> 31)

    if decrypt {
        for i in 0..<8 {
            (left, right) =
                feistel(l: left, r: right,
                        k0: subkeys[15 - 2 * i],
                        k1: subkeys[15 - (2 * i + 1)])
        }
    } else {
        for i in 0..<8 {
            (left, right) =
                feistel(l: left, r: right,
                        k0: subkeys[2 * i],
                        k1: subkeys[2 * i + 1])
        }
    }

    left = (left << 31) | (left >> 1)
    right = (right << 31) | (right >> 1)

    // switch left & right and perform final permutation
    let preOutput = (UInt64(right) << 32) | UInt64(left)
    return permuteFinalBlock(block: preOutput).bigEndianData
}


/// permuteInitialBlock is equivalent to the permutation defined by initialPermutation.

private func permuteInitialBlock(block: UInt64) -> UInt64 {
    var block: UInt64 = block

    // block = b7 b6 b5 b4 b3 b2 b1 b0 (8 bytes)
    var b1 = block >> 48
    var b2 = block << 48
    let t1 = b1 << 48
    let t2 = b2 >> 48
    block ^= b1 ^ b2 ^ t1 ^ t2

    // block = b1 b0 b5 b4 b3 b2 b7 b6
    b1 = block >> 32 & 0xff00ff
    b2 = (block & 0xff00ff00)
    let t3 = b1 << 32
    let t4 = b1 << 8
    let t5 = b2 << 24
    block ^= t3 ^ b2 ^ t4 ^ t5 // exchange b0 b4 with b3 b7

    // block is now b1 b3 b5 b7 b0 b2 b4 b7, the permutation:
    //                  ...  8
    //                  ... 24
    //                  ... 40
    //                  ... 56
    //  7  6  5  4  3  2  1  0
    // 23 22 21 20 19 18 17 16
    //                  ... 32
    //                  ... 48

    // exchange 4,5,6,7 with 32,33,34,35 etc.
    b1 = block & 0x0f0f00000f0f0000
    b2 = block & 0x0000f0f00000f0f0
    let t6 = b1 >> 12
    let t7 = b2 << 12
    block ^= b1 ^ b2 ^ t6 ^ t7

    // block is the permutation:
    //
    //   [+8]         [+40]
    //
    //  7  6  5  4
    // 23 22 21 20
    //  3  2  1  0
    // 19 18 17 16    [+32]

    // exchange 0,1,4,5 with 18,19,22,23
    b1 = block & 0x3300330033003300
    b2 = block & 0x00cc00cc00cc00cc
    let t8 = b1 >> 6
    let t9 = b2 << 6
    block ^= b1 ^ b2 ^ t8 ^ t9

    // block is the permutation:
    // 15 14
    // 13 12
    // 11 10
    //  9  8
    //  7  6
    //  5  4
    //  3  2
    //  1  0 [+16] [+32] [+64]

    // exchange 0,2,4,6 with 9,11,13,15:
    b1 = block & 0xaaaaaaaa55555555
    let t10 = b1 >> 33
    let t11 = b1 << 33
    block ^= b1 ^ t10 ^ t11

    // block is the permutation:
    // 6 14 22 30 38 46 54 62
    // 4 12 20 28 36 44 52 60
    // 2 10 18 26 34 42 50 58
    // 0  8 16 24 32 40 48 56
    // 7 15 23 31 39 47 55 63
    // 5 13 21 29 37 45 53 61
    // 3 11 19 27 35 43 51 59
    // 1  9 17 25 33 41 49 57
    return block
}


/// permuteFinalBlock is equivalent to the permutation defined by finalPermutation.

func permuteFinalBlock(block: UInt64) -> UInt64 {
    var block = block

    // Perform the same bit exchanges as permuteInitialBlock
    // but in reverse order.
    var b1 = block & 0xaaaaaaaa55555555
    let t1 = b1 >> 33
    let t2 = b1 << 33
    block ^= b1 ^ t1 ^ t2

    b1 = block & 0x3300330033003300
    var b2 = block & 0x00cc00cc00cc00cc
    let t3 = b1 >> 6
    let t4 = b2 << 6
    block ^= b1 ^ b2 ^ t3 ^ t4

    b1 = block & 0x0f0f00000f0f0000
    b2 = block & 0x0000f0f00000f0f0
    let t5 = b1 >> 12
    let t6 = b2 << 12
    block ^= b1 ^ b2 ^ t5 ^ t6

    b1 = block >> 32 & 0xff00ff
    b2 = (block & 0xff00ff00)
    let t7 = b1 << 32
    let t8 = b1 << 8
    let t9 = b2 << 24
    block ^= t7 ^ b2 ^ t8 ^ t9

    b1 = block >> 48
    b2 = block << 48
    let t10 = b1 << 48
    let t11 = b2 >> 48
    block ^= b1 ^ b2 ^ t10 ^ t11
    return block
}


/// 8 S-boxes composed of 4 rows and 16 columns. Used in the DES cipher function

private let sBoxes: [[[UInt8]]] = [
    // S-box 1
    [
        [14, 4, 13, 1, 2, 15, 11, 8, 3, 10, 6, 12, 5, 9, 0, 7] as [UInt8],
        [0, 15, 7, 4, 14, 2, 13, 1, 10, 6, 12, 11, 9, 5, 3, 8] as [UInt8],
        [4, 1, 14, 8, 13, 6, 2, 11, 15, 12, 9, 7, 3, 10, 5, 0] as [UInt8],
        [15, 12, 8, 2, 4, 9, 1, 7, 5, 11, 3, 14, 10, 0, 6, 13] as [UInt8],
    ],
    // S-box 2
    [
        [15, 1, 8, 14, 6, 11, 3, 4, 9, 7, 2, 13, 12, 0, 5, 10] as [UInt8],
        [3, 13, 4, 7, 15, 2, 8, 14, 12, 0, 1, 10, 6, 9, 11, 5] as [UInt8],
        [0, 14, 7, 11, 10, 4, 13, 1, 5, 8, 12, 6, 9, 3, 2, 15] as [UInt8],
        [13, 8, 10, 1, 3, 15, 4, 2, 11, 6, 7, 12, 0, 5, 14, 9] as [UInt8],
    ],
    // S-box 3
    [
        [10, 0, 9, 14, 6, 3, 15, 5, 1, 13, 12, 7, 11, 4, 2, 8] as [UInt8],
        [13, 7, 0, 9, 3, 4, 6, 10, 2, 8, 5, 14, 12, 11, 15, 1] as [UInt8],
        [13, 6, 4, 9, 8, 15, 3, 0, 11, 1, 2, 12, 5, 10, 14, 7] as [UInt8],
        [1, 10, 13, 0, 6, 9, 8, 7, 4, 15, 14, 3, 11, 5, 2, 12] as [UInt8],
    ],
    // S-box 4
    [
        [7, 13, 14, 3, 0, 6, 9, 10, 1, 2, 8, 5, 11, 12, 4, 15] as [UInt8],
        [13, 8, 11, 5, 6, 15, 0, 3, 4, 7, 2, 12, 1, 10, 14, 9] as [UInt8],
        [10, 6, 9, 0, 12, 11, 7, 13, 15, 1, 3, 14, 5, 2, 8, 4] as [UInt8],
        [3, 15, 0, 6, 10, 1, 13, 8, 9, 4, 5, 11, 12, 7, 2, 14] as [UInt8],
    ],
    // S-box 5
    [
        [2, 12, 4, 1, 7, 10, 11, 6, 8, 5, 3, 15, 13, 0, 14, 9] as [UInt8],
        [14, 11, 2, 12, 4, 7, 13, 1, 5, 0, 15, 10, 3, 9, 8, 6] as [UInt8],
        [4, 2, 1, 11, 10, 13, 7, 8, 15, 9, 12, 5, 6, 3, 0, 14] as [UInt8],
        [11, 8, 12, 7, 1, 14, 2, 13, 6, 15, 0, 9, 10, 4, 5, 3] as [UInt8],
    ],
    // S-box 6
    [
        [12, 1, 10, 15, 9, 2, 6, 8, 0, 13, 3, 4, 14, 7, 5, 11] as [UInt8],
        [10, 15, 4, 2, 7, 12, 9, 5, 6, 1, 13, 14, 0, 11, 3, 8] as [UInt8],
        [9, 14, 15, 5, 2, 8, 12, 3, 7, 0, 4, 10, 1, 13, 11, 6] as [UInt8],
        [4, 3, 2, 12, 9, 5, 15, 10, 11, 14, 1, 7, 6, 0, 8, 13] as [UInt8],
    ],
    // S-box 7
    [
        [4, 11, 2, 14, 15, 0, 8, 13, 3, 12, 9, 7, 5, 10, 6, 1] as [UInt8],
        [13, 0, 11, 7, 4, 9, 1, 10, 14, 3, 5, 12, 2, 15, 8, 6] as [UInt8],
        [1, 4, 11, 13, 12, 3, 7, 14, 10, 15, 6, 8, 0, 5, 9, 2] as [UInt8],
        [6, 11, 13, 8, 1, 4, 10, 7, 9, 5, 0, 15, 14, 2, 3, 12] as [UInt8],
    ],
    // S-box 8
    [
        [13, 2, 8, 4, 6, 15, 11, 1, 10, 9, 3, 14, 5, 0, 12, 7] as [UInt8],
        [1, 15, 13, 8, 10, 3, 7, 4, 12, 5, 6, 11, 0, 14, 9, 2] as [UInt8],
        [7, 11, 4, 1, 9, 12, 14, 2, 0, 6, 10, 13, 15, 3, 5, 8] as [UInt8],
        [2, 1, 14, 7, 4, 10, 8, 13, 15, 12, 9, 0, 3, 5, 6, 11] as [UInt8],
    ],
]


/// Yields a 32-bit output from a 32-bit input

private let permutationFunction: [UInt8] = [
    16, 25, 12, 11, 3, 20, 4, 15,
    31, 17, 9, 6, 27, 14, 1, 22,
    30, 24, 8, 18, 0, 5, 29, 23,
    13, 19, 2, 26, 10, 21, 28, 7,
]


/// feistelBox[s][16*i+j] contains the output of permutationFunction
/// for sBoxes[s][i][j] << 4*(7-s)

private let feistelBox: [[UInt32]] = computeFeistelBox()


private func computeFeistelBox() -> [[UInt32]] {
    var feistelBox = [[UInt32]](repeating: [UInt32](repeating: 0, count: 64), count: 8)

    for (s, sBox) in sBoxes.enumerated() {
        for i in 0..<4 {
            for j in 0..<16 {
                var f = UInt64(sBox[i][j]) << (4 * (7 - UInt(s)))
                f = permuteBlock(source: f, permutation: permutationFunction)

                // Row is determined by the 1st and 6th bit.
                // Column is the middle four bits.
                let t1 = (i & 2)
                let t2 = (t1 << 4)
                let t3 = i & 1
                let row = UInt8(t2 | t3)
                let col = UInt8(j << 1)
                let t = row | col

                // The rotation was performed in the feistel rounds,
                // being factored out and now mixed into the feistelBox.
                f = (f << 1) | (f >> 31)
                feistelBox[s][Int(t)] = UInt32(truncatingIfNeeded: f)
            }
        }
    }
    return feistelBox
}


/// DES Feistel function

private func feistel(l: UInt32, r: UInt32, k0: UInt64, k1: UInt64) -> (UInt32, UInt32) {

    var t: UInt32 = 0

    var l: UInt32 = l
    var r: UInt32 = r

    t = r ^ UInt32(truncatingIfNeeded: k0 >> 32)
    let x1: UInt32 = feistelBox[7][Int(t & 0x3f)]
    let x2: UInt32 = feistelBox[5][Int((t >> 8) & 0x3f)]
    let x3: UInt32 = feistelBox[3][Int((t >> 16) & 0x3f)]
    let x4: UInt32 = feistelBox[1][Int((t >> 24) & 0x3f)]
    l ^= x1 ^ x2 ^ x3 ^ x4

    t = ((r << 28) | (r >> 4)) ^ UInt32(truncatingIfNeeded: k0)
    let y1: UInt32 = feistelBox[6][Int(t & 0x3f)]
    let y2: UInt32 = feistelBox[4][Int((t >> 8) & 0x3f)]
    let y3: UInt32 = feistelBox[2][Int((t >> 16 ) & 0x3f)]
    let y4: UInt32 = feistelBox[0][Int((t >> 24 ) & 0x3f)]
    l ^= y1 ^ y2 ^ y3 ^ y4

    t = l ^ UInt32(truncatingIfNeeded: k1 >> 32)
    let c1: UInt32 = feistelBox[7][Int(t & 0x3f)]
    let c2: UInt32 = feistelBox[5][Int((t >> 8) & 0x3f)]
    let c3: UInt32 = feistelBox[3][Int((t >> 16) & 0x3f)]
    let c4: UInt32 = feistelBox[1][Int((t >> 24) & 0x3f)]
    r ^= c1 ^ c2 ^ c3 ^ c4

    t = ((l << 28) | (l >> 4)) ^ UInt32(truncatingIfNeeded: k1)
    let d1: UInt32 = feistelBox[6][Int(t & 0x3f)]
    let d2: UInt32 = feistelBox[4][Int((t >> 8) & 0x3f)]
    let d3: UInt32 = feistelBox[2][Int((t >> 16) & 0x3f)]
    let d4: UInt32 = feistelBox[0][Int((t >> 24) & 0x3f)]

    r ^= d1 ^ d2 ^ d3 ^ d4

    return (l, r)
}


public struct DES {

    public let subkeys: [UInt64]

    public init(keyBytes: [UInt8]) throws {
        subkeys = try generateSubkeys(keyBytes)
    }

    public func encrypt(source: Data) -> Data? {
        return cryptBlock(subkeys: subkeys, source: source, decrypt: false)
    }

    public func decrypt(source: Data) -> Data? {
        return cryptBlock(subkeys: subkeys, source: source, decrypt: true)
    }
}
