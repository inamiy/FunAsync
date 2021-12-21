// MARK: - asyncAll (non-throwing)

/// Runs multiple `fs` concurrently and returns all values.
/// This method is equivalent to `Promise.all` in JavaScript.
public func asyncAll<B>(_ fs: [() async -> B]) -> () async -> [B]
{
    precondition(!fs.isEmpty, "asyncAll error: async array is empty.")

    return {
        let fs_: [(()) async -> B] = fs.map { f in { _ in await f() } }
        return await asyncAll(fs_)(())
    }
}

/// Runs multiple `fs` concurrently and returns all values.
/// This method is equivalent to `Promise.all` in JavaScript.
public func asyncAll<A, B>(_ fs: [(A) async -> B]) -> (A) async -> [B]
{
    precondition(!fs.isEmpty, "asyncAll error: async array is empty.")

    return { a in
        await withTaskGroup(of: (Int, B).self) { group in
            for (i, f) in fs.enumerated() {
                group.addTask {
                    (i, await f(a))
                }
            }

            return await group
                .reduce(into: [], { $0.append($1) })
                .sorted(by: { $0.0 < $1.0 })
                .map { $1 }
        }
    }
}

// MARK: - asyncAll (throwing)

/// Runs multiple `fs` concurrently and returns all values, where first error may be thrown.
/// This method is equivalent to `Promise.all` in JavaScript.
public func asyncAll<B>(_ fs: [() async throws -> B]) -> () async throws -> [B]
{
    precondition(!fs.isEmpty, "asyncAll error: async array is empty.")

    return {
        let fs_: [(()) async throws -> B] = fs.map { f in { _ in try await f() } }
        return try await asyncAll(fs_)(())
    }
}

/// Runs multiple `fs` concurrently and returns all values, where first error may be thrown.
/// This method is equivalent to `Promise.all` in JavaScript.
public func asyncAll<A, B>(_ fs: [(A) async throws -> B]) -> (A) async throws -> [B]
{
    precondition(!fs.isEmpty, "asyncAll error: async array is empty.")

    return { a in
        try await withThrowingTaskGroup(of: (Int, B).self) { group in
            for (i, f) in fs.enumerated() {
                group.addTask {
                    (i, try await f(a))
                }
            }

            return try await group
                .reduce(into: [], { $0.append($1) })
                .sorted(by: { $0.0 < $1.0 })
                .map { $1 }
        }
    }
}
