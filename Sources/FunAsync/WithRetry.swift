/// Retries `f` when failed, until `when` throws an error.
public func withRetry<B>(
    when: (Error, _ failedCount: UInt64) async throws -> Void,
    run: @escaping () async throws -> B
) async throws -> B
{
    var failedCount: UInt64 = 0

    while true {
        do {
            return try await run()
        }
        catch {
            failedCount += 1
            try await when(error, failedCount)
        }
    }
}

/// Retries `f` when failed, until failed count reaches`count`.
///
/// Additionally, retry with customizable `delay` is also supported for exponential backoff,
/// e.g. `delay = { UInt64(pow(2, (Double($1) - 1))) * initialExponentialBackoffNanoseconds }`
public func withRetry<B>(
    maxCount: UInt64,
    delay: (Error, _ failedCount: UInt64) -> UInt64 = { _, _ in 0 },
    run: @escaping () async throws -> B
) async throws -> B
{
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
    )
}
