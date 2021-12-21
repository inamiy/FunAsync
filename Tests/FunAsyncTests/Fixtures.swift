func makeAsync<T>(_ id: String, sleep: UInt64, result: Result<T, Error>) async throws -> T {
    return try await withTaskCancellationHandler {
        debugLog("async \(id) start")

        let loopCount: UInt64 = sleep / shortSleep

        // NOTE: for-loop for quick cancellation without too much sleep.
        for _ in 0 ... loopCount {
            try await Task.sleep(nanoseconds: shortSleep)

            do {
                try Task.checkCancellation()
            } catch {
                debugLog("async \(id) cancelled")
                throw error
            }
        }

        switch result {
        case let .success(value):
            debugLog("async \(id) succeeded")
            return value
        case let .failure(error):
            debugLog("async \(id) failed")
            throw error
        }

    } onCancel: {
        debugLog("async \(id) onCancel")
    }
}

private let shortSleep: UInt64 = 10_000_000 // sleep per loop

/// Recommended minimum sleep interval = 100 ms.
let sleepUnit: UInt64 = shortSleep * 10

struct MyError: Error, Equatable
{
    var message: String = ""
}

struct EqError: Error, Equatable
{
    let error: String

    init(_ error: Error)
    {
        self.error = error.localizedDescription
    }
}

private func debugLog(_ msg: Any) {
    print(msg)
}
