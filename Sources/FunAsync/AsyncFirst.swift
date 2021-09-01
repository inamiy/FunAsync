// MARK: - asyncFirst (non-throwing)

/// Runs multiple `fs` concurrently and returns the first arrival.
/// This method is equivalent to `Promise.race` or `Promise.any` (without errors) in JavaScript.
public func asyncFirst<B>(_ fs: [() async -> B]) -> () async -> B
{
    precondition(!fs.isEmpty, "asyncFirst error: async array is empty.")

    return {
        let fs_: [(()) async -> B] = fs.map { f in { _ in await f() } }
        return await asyncFirst(fs_)(())
    }
}

/// Runs multiple `fs` concurrently and returns the first arrival.
/// This method is equivalent to `Promise.race` or `Promise.any` (without errors) in JavaScript.
public func asyncFirst<A, B>(_ fs: [(A) async -> B]) -> (A) async -> B
{
    precondition(!fs.isEmpty, "asyncFirst error: async array is empty.")

    return { a in
        await withTaskGroup(of: B.self) { group in
            for f in fs {
                group.addTask {
                    await f(a)
                }
            }

            let first = await group.next()!

            // Cancel others when first result is arrived (either success or error).
            group.cancelAll()

            return first
        }
    }
}

// MARK: - asyncFirst (throwing)

/// Runs multiple `fs` concurrently and returns the first arrival, which can be either success or error.
/// This method is equivalent to `Promise.race` in JavaScript.
public func asyncFirst<B>(_ fs: [() async throws -> B]) -> () async throws -> B
{
    precondition(!fs.isEmpty, "asyncFirst error: async array is empty.")

    return {
        let fs_: [(()) async throws -> B] = fs.map { f in { _ in try await f() } }
        return try await asyncFirst(fs_)(())
    }
}

/// Runs multiple `fs` concurrently and returns the first arrival, which can be either success or error.
/// This method is equivalent to `Promise.race` in JavaScript.
public func asyncFirst<A, B>(_ fs: [(A) async throws -> B]) -> (A) async throws -> B
{
    precondition(!fs.isEmpty, "asyncFirst error: async array is empty.")

    return { a in
        try await asyncResultToAsyncThrows {
            await withTaskGroup(of: Result<B, Error>.self) { group -> Result<B, Error> in
                for f in fs {
                    group.addTask {
                        return await asyncThrowsToAsyncResult {
                            try await f(a)
                        }(())
                    }
                }
                let first = await group.next()!
                group.cancelAll()
                return first
            }
        }(())
    }
}
