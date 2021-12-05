public func withTimeout<B>(
    nanoseconds: UInt64,
    run: @escaping () async throws -> B
) async throws -> B
{
    let timeout: () async throws -> B? = {
        try await Task.sleep(nanoseconds: nanoseconds)
        return .none
    }

    let k = asyncFirst([run, timeout])

    if let value = try await k() {
        return value
    }
    else {
        throw TimeoutCancellationError()
    }
}

public struct TimeoutCancellationError : Error {}
