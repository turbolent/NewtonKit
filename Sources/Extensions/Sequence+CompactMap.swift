
#if swift(>=4.1)
#else
extension Sequence {
    func compactMap<ElementOfResult>(_ transform: (Self.Element) throws -> ElementOfResult?)
        rethrows -> [ElementOfResult]
    {
        return try flatMap(transform)
    }
}
#endif
