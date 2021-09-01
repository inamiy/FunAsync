// MARK: - `async throws` to `async Result`

/// Converts from `async throws` to `async Result` in JavaScript.
public func asyncThrowsToAsyncResult<A, B>(_ f: @escaping (A) async throws -> B)
    -> (A) async -> Result<B, Error>
{
    { a in
        do {
            return .success(try await f(a))
        } catch {
            return .failure(error)
        }
    }
}

// MARK: - `async Result` to `async throws`

/// Converts from `async Result` to `async throws` in JavaScript.
public func asyncResultToAsyncThrows<A, B>(_ f: @escaping (A) async -> Result<B, Error>)
    -> (A) async throws -> B
{
    { a in
        switch await f(a) {
        case let .success(success):
            return success
        case let .failure(error):
            throw error
        }
    }
}
