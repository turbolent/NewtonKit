
public func toContext<T: AnyObject>(object: T) -> UnsafeMutableRawPointer {
    return Unmanaged.passUnretained(object).toOpaque()
}

public func fromContext<T: AnyObject>(pointer: UnsafeMutableRawPointer) -> T {
    return Unmanaged<T>.fromOpaque(pointer).takeUnretainedValue()
}
