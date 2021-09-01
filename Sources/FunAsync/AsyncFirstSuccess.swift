/// Runs multiple `fs` concurrently and returns the first successful value, ignoring the error arrivals.
/// This method is equivalent to `Promise.any` in JavaScript.
public func asyncFirstSuccess<B>(_ fs: [() async throws -> B]) -> () async -> B?
{
    precondition(!fs.isEmpty, "asyncFirstSuccess error: async array is empty.")

    return {
        let fs_: [(()) async throws -> B] = fs.map { f in { _ in try await f() } }
        return await asyncFirstSuccess(fs_)(())
    }
}

/// Runs multiple `fs` concurrently and returns the first successful value, ignoring the error arrivals.
/// This method is equivalent to `Promise.any` in JavaScript.
public func asyncFirstSuccess<A, B>(_ fs: [(A) async throws -> B]) -> (A) async -> B?
{
    precondition(!fs.isEmpty, "asyncFirstSuccess error: async array is empty.")

    return { a in
        await withTaskGroup(of: Result<B, Error>.self) { group -> B? in
            for f in fs {
                group.addTask {
                    return await asyncThrowsToAsyncResult {
                        try await f(a)
                    }(())
                }
            }

            for await case let .success(value) in group {
                group.cancelAll() // Cancel others when first successful value is arrived.
                return value
            }

            return nil
        }
    }
}
