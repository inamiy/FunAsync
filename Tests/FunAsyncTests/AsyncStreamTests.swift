import XCTest
@testable import FunAsync

final class AsyncStreamTests: XCTestCase
{
    func testAsyncStream() async throws
    {
        // NOTE: Using `try?` to ignore throwing-function part.
        let values = asyncStream([
            { try? await makeAsync("1", sleep: sleepUnit, result: .success(1)) },
            { try? await makeAsync("2", sleep: sleepUnit * 2, result: .success(2)) }
        ])()

        var results: [Int?] = []

        for await value in values {
            results.append(value)
        }

        XCTAssertEqual(results, [1, 2])
    }

    func testAsyncStream_success() async throws
    {
        let values = asyncStream([
            { try await makeAsync("1", sleep: sleepUnit, result: .success(1)) },
            { try await makeAsync("2", sleep: sleepUnit * 2, result: .success(2)) }
        ])()

        var results: [Int?] = []

        do {
            for try await value in values {
                results.append(value)
            }
        }
        catch {
            XCTFail("Should never reach here")
        }

        XCTAssertEqual(results, [1, 2])
    }

    func testAsyncStream_fail_1st() async throws
    {
        let values = asyncStream([
            { try await makeAsync("1", sleep: sleepUnit, result: .failure(MyError())) },
            { try await makeAsync("2", sleep: sleepUnit * 2, result: .success(2)) }
        ])()

        var results: [Int?] = []

        do {
            for try await value in values {
                results.append(value)
            }
            XCTFail("Should never reach here")
        }
        catch let error as MyError {
            XCTAssertEqual(error, MyError(), "First arrival should be MyError.")
            XCTAssertEqual(results, [], "No values should arrive.")
        }
        catch {
            XCTFail("Should never reach here.")
        }
    }

    func testAsyncStream_fail_2nd() async throws
    {
        let values = asyncStream([
            { try await makeAsync("1", sleep: sleepUnit, result: .success(1)) },
            { try await makeAsync("2", sleep: sleepUnit * 2, result: .failure(MyError())) }
        ])()

        var results: [Int?] = []

        do {
            for try await value in values {
                results.append(value)
            }
            XCTFail("Should never reach here")
        }
        catch let error as MyError {
            XCTAssertEqual(error, MyError(), "First arrival should be MyError.")
            XCTAssertEqual(results, [1], "1st value should arrive.")
        }
        catch {
            XCTFail("Should never reach here.")
        }
    }

    func testAsyncStream_sibling_cancelling() async throws
    {
        actor Box {
            var isSiblingCancelled = false

            func toggle() {
                isSiblingCancelled.toggle()
            }
        }

        let box = Box()

        let values = asyncStream([
            { try await makeAsync("1", sleep: sleepUnit, result: .failure(MyError())) },
            {
                try await withTaskCancellationHandler {
                    try await makeAsync("2", sleep: sleepUnit * 2, result: .success(2))
                } onCancel: {
                    Task.init { await box.toggle() }
                }
            }
        ])()

        var results: [Int?] = []

        do {
            for try await value in values {
                results.append(value)
            }
            XCTFail("Should never reach here")
        }
        catch let error as MyError {
            XCTAssertEqual(error, MyError(), "First arrival should be MyError.")
            XCTAssertEqual(results, [], "No values should arrive.")
        }
        catch {
            XCTFail("Should never reach here.")
        }

        let isSiblingCancelled = await box.isSiblingCancelled
        XCTAssertTrue(isSiblingCancelled, "Should cancel other running asyncs")
    }

    func testAsyncStream_wrapper_cancelling() async throws
    {
        actor Box {
            var isSiblingCancelled = false

            func toggle() {
                isSiblingCancelled.toggle()
            }
        }

        let box1 = Box()
        let box2 = Box()

        let wrapperTask = Task<Void, Error> {
            let stream = asyncStream([
                {
                    try await withTaskCancellationHandler {
                        try await makeAsync("1", sleep: sleepUnit, result: .success(1))
                    } onCancel: {
                        Task.init { await box1.toggle() }
                    }
                },
                {
                    try await withTaskCancellationHandler {
                        try await makeAsync("2", sleep: sleepUnit * 3, result: .success(2))
                    } onCancel: {
                        Task.init { await box2.toggle() }
                    }
                }
            ])()

            return try await stream.reduce(into: ()) { _, _ in }
        }

        // Add short tick before cancellation.
        try await Task.sleep(nanoseconds: sleepUnit * 2)

        // Then cancel.
        wrapperTask.cancel()

        // Wait for completion.
        try await wrapperTask.value

        let isSiblingCancelled1 = await box1.isSiblingCancelled
        let isSiblingCancelled2 = await box2.isSiblingCancelled

        XCTAssertFalse(isSiblingCancelled1, "Async 1 should be completed before cancellation.")
        XCTAssertTrue(isSiblingCancelled2, "Should cancel other running asyncs")
    }
}
