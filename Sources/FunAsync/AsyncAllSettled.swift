/// Runs multiple `fs` concurrently and returns all results (values and errors).
/// This method is equivalent to `Promise.allSettled` in JavaScript.
public func asyncAllSettled<B>(_ fs: [() async throws -> B]) -> () async -> [Result<B, Error>]
{
    precondition(!fs.isEmpty, "asyncAllSettled error: async array is empty.")

    return {
        let fs_: [(()) async throws -> B] = fs.map { f in { _ in try await f() } }
        return await asyncAllSettled(fs_)(())
    }
}

/// Runs multiple `fs` concurrently and returns all results (values and errors).
/// This method is equivalent to `Promise.allSettled` in JavaScript.
public func asyncAllSettled<A, B>(_ fs: [(A) async throws -> B]) -> (A) async -> [Result<B, Error>]
{
    precondition(!fs.isEmpty, "asyncAllSettled error: async array is empty.")

    return { a in
        await withTaskGroup(of: (Int, Result<B, Error>).self) { group in
            for (i, f) in fs.enumerated() {
                group.addTask {
                    do {
                        return (i, .success(try await f(a)))
                    }
                    catch {
                        return (i, .failure(error))
                    }
                }
            }

            return await group
                .reduce(into: [], { $0.append($1) })
                .sorted(by: { $0.0 < $1.0 })
                .map { $1 }
        }
    }
}
