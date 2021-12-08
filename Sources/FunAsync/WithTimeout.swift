/// Adds timeout that races with `run`.
public func withTimeout<B>(
    nanoseconds: UInt64,
    run: @escaping () async throws -> B
) -> () async throws -> B
{
    {
        try await withTimeout(nanoseconds: nanoseconds, run: { () in
            try await run()
        })(())
    }
}

/// Adds timeout that races with `run`.
public func withTimeout<A, B>(
    nanoseconds: UInt64,
    run: @escaping (A) async throws -> B
) -> (A) async throws -> B
{
    { a in
        let timeout: (A) async throws -> B? = { _ in
            try await Task.sleep(nanoseconds: nanoseconds)
            return .none
        }

        let race = asyncFirst([run, timeout])

        if let value = try await race(a) {
            return value
        }
        else {
            throw TimeoutCancellationError()
        }
    }
}

// MARK: - TimeoutCancellationError

public struct TimeoutCancellationError : Error {}
