/// Retries `run` when failed, until `when` throws an error.
public func withRetry<B>(
    when: @escaping (Error, _ failedCount: UInt64) async throws -> Void,
    run: @escaping () async throws -> B
) -> () async throws -> B
{
    {
        try await withRetry(when: when, run: { _ in try await run() })(())
    }
}

/// Retries `run` when failed, until `when` throws an error.
public func withRetry<A, B>(
    when: @escaping (Error, _ failedCount: UInt64) async throws -> Void,
    run: @escaping (A) async throws -> B
) -> (A) async throws -> B
{
    { a in
        var failedCount: UInt64 = 0

        while true {
            do {
                return try await run(a)
            }
            catch {
                failedCount += 1
                try await when(error, failedCount)
            }
        }
    }
}

// MARK: - withRetry + exponential backoff

/// Retries `run` when failed, until failed count reaches`count`.
///
/// Additionally, retry with customizable `delay` is also supported for exponential backoff,
/// e.g. `delay = { UInt64(pow(2, (Double($1) - 1))) * initialExponentialBackoffNanoseconds }`
public func withRetry<B>(
    maxCount: UInt64,
    delay: @escaping (Error, _ failedCount: UInt64) -> UInt64 = { _, _ in 0 },
    run: @escaping () async throws -> B
) -> () async throws -> B
{
    {
        try await withRetry(
            maxCount: maxCount,
            delay: delay,
            run: { () in
                try await run()
            }
        )(())
    }
}

/// Retries `run` when failed, until failed count reaches`count`.
///
/// Additionally, retry with customizable `delay` is also supported for exponential backoff,
/// e.g. `delay = { UInt64(pow(2, (Double($1) - 1))) * initialExponentialBackoffNanoseconds }`
public func withRetry<A, B>(
    maxCount: UInt64,
    delay: @escaping (Error, _ failedCount: UInt64) -> UInt64 = { _, _ in 0 },
    run: @escaping (A) async throws -> B
) -> (A) async throws -> B
{
    { a in
        try await withRetry(
            when: { error, failedCount in
                if failedCount <= maxCount {
                    let delayValue = delay(error, failedCount)
                    if delayValue > 0 {
                        try await Task.sleep(nanoseconds: delayValue)
                    }
                    return ()
                } else {
                    throw error
                }
            },
            run: run
        )(a)
    }
}
