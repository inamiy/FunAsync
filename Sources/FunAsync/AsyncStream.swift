// MARK: - asyncStream (non-throwing)

/// Runs multiple `fs` concurrently and returns its `AsyncStream`.
public func asyncStream<B>(_ fs: [() async -> B]) -> () -> AsyncStream<B>
{
    precondition(!fs.isEmpty, "asyncAll error: async array is empty.")

    return {
        let fs_: [(()) async -> B] = fs.map { f in { _ in await f() } }
        return asyncStream(fs_)(())
    }
}

/// Runs multiple `fs` concurrently and returns its `AsyncStream`.
public func asyncStream<A, B>(_ fs: [(A) async -> B]) -> (A) -> AsyncStream<B>
{
    precondition(!fs.isEmpty, "asyncStream error: async array is empty.")

    return { a in
        AsyncStream { continuation in
            let task = Task {
                await withTaskGroup(of: B.self) { group in
                    for f in fs {
                        group.addTask {
                            await f(a)
                        }
                    }

                    for await value in group {
                        continuation.yield(value)
                    }
                    continuation.finish()
                }
            }

            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }
}

// MARK: - asyncStream (throwing)

/// Runs multiple `fs` concurrently and returns its `AsyncThrowingStream`.
public func asyncStream<B>(_ fs: [() async throws -> B]) -> () -> AsyncThrowingStream<B, Error>
{
    precondition(!fs.isEmpty, "asyncAll error: async array is empty.")

    return {
        let fs_: [(()) async throws -> B] = fs.map { f in { _ in try await f() } }
        return asyncStream(fs_)(())
    }
}

/// Runs multiple `fs` concurrently and returns its `AsyncThrowingStream`.
public func asyncStream<A, B>(_ fs: [(A) async throws -> B]) -> (A) -> AsyncThrowingStream<B, Error>
{
    precondition(!fs.isEmpty, "asyncStream error: async array is empty.")

    return { a in
        AsyncThrowingStream { continuation in
            let task = Task {
                await withThrowingTaskGroup(of: B.self) { group in
                    for f in fs {
                        group.addTask {
                            try await f(a)
                        }
                    }

                    do {
                        for try await value in group {
                            continuation.yield(value)
                        }
                        continuation.finish()
                    }
                    catch {
                        continuation.finish(throwing: error)
                    }
                }
            }

            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }
}
