import Foundation

// MARK: - Transfer Progress

public enum RequestProgress<T: Sendable>: Sendable {
    case progress(Double)
    case completed(T)
}
