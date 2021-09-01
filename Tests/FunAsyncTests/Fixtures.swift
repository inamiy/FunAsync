func makeAsync(_ id: String, sleep: UInt64, isSuccess: Bool = true) async throws -> Int {
    return try await withTaskCancellationHandler {
        debugLog("async \(id) start")

        // NOTE: for-loop for quick cancellation without too much sleep.
        let _10ms: UInt64 = 10_000_000
        for _ in 0 ... sleep * 10 {
            await Task.sleep(_10ms)

            do {
                try Task.checkCancellation()
            } catch {
                debugLog("async \(id) cancelled")
                throw error
            }
        }

        if isSuccess {
            debugLog("async \(id) succeeded")
            return Int(sleep)
        } else {
            debugLog("async \(id) failed")
            throw MyError()
        }
    } onCancel: {
        debugLog("async \(id) onCancel")
    }
}

struct MyError: Error, Equatable {}

private func debugLog(_ msg: Any) {
    print(msg)
}
