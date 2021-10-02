extension AsyncSequence
{
    /// `AsyncSequence` to `AsyncThrowingStream`.
    public func toAsyncThrowingStream() -> AsyncThrowingStream<Element, Error>
    {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    for try await value in self {
                        continuation.yield(value)
                    }
                    continuation.finish(throwing: nil)
                }
                catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }

    /// `AsyncSequence` to `toAsyncStream`, discarding error.
    public func toAsyncStream() -> AsyncStream<Element>
    {
        AsyncStream { continuation in
            let task = Task {
                do {
                    for try await value in self {
                        continuation.yield(value)
                    }
                    continuation.finish()
                }
                catch {
                    continuation.finish()
                }
            }

            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }
}
