/// Runs `fs[0]`, and if it fails will run `fs[1]`, and so on, until first one succeeds.
/// - Throws: `fs.last` error.
public func asyncOr<B>(_ fs: [() async throws -> B]) -> () async throws -> B
{
    precondition(!fs.isEmpty, "asyncOr error: async array is empty.")

    return {
        var lastError: Error?

        for f in fs {
            do {
                return try await f()
            }
            catch {
                lastError = error
            }
        }

        throw lastError!
    }
}
