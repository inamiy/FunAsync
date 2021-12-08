/// Runs `fs[0]`, and if it fails will run `fs[1]`, and so on, until first one succeeds.
/// - Throws: `fs.last` error.
public func asyncOr<B>(_ fs: [() async throws -> B]) -> () async throws -> B
{
    precondition(!fs.isEmpty, "asyncOr error: async array is empty.")

    return {
        let fs_: [(()) async throws -> B] = fs.map { f in { _ in try await f() } }
        return try await asyncOr(fs_)(())
    }
}

/// Runs `fs[0]`, and if it fails will run `fs[1]`, and so on, until first one succeeds.
/// - Throws: `fs.last` error.
public func asyncOr<A, B>(_ fs: [(A) async throws -> B]) -> (A) async throws -> B
{
    precondition(!fs.isEmpty, "asyncOr error: async array is empty.")

    return { a in
        var lastError: Error?

        for f in fs {
            do {
                return try await f(a)
            }
            catch {
                lastError = error
            }
        }

        throw lastError!
    }
}
