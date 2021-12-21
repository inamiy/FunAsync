import XCTest
@testable import FunAsync

final class AsyncAllTests: XCTestCase
{
    func testNonThrowingAsyncAll() async throws
    {
        // NOTE: Using `try?` to ignore throwing-function part.
        let values = await asyncAll([
            { try? await makeAsync("1", sleep: sleepUnit, result: .success(1)) },
            { try? await makeAsync("2", sleep: sleepUnit * 2, result: .success(2)) }
        ])()

        XCTAssertEqual(values, [1, 2])
    }

    func testNonThrowingAsyncAll2() async throws
    {
        // NOTE: Using `try?` to ignore throwing-function part.
        let values = await asyncAll([
            { try? await makeAsync("1", sleep: sleepUnit * 2, result: .success(1)) },
            { try? await makeAsync("2", sleep: sleepUnit, result: .success(2)) }
        ])()

        XCTAssertEqual(values, [1, 2],
                       "Should not affect order")
    }

    func testAsyncAll_success() async throws
    {
        let values = try await asyncAll([
            { try await makeAsync("1", sleep: sleepUnit, result: .success(1)) },
            { try await makeAsync("2", sleep: sleepUnit * 2, result: .success(2)) }
        ])()

        XCTAssertEqual(values, [1, 2])
    }

    func testAsyncAll_success2() async throws
    {
        let values = try await asyncAll([
            { try await makeAsync("1", sleep: sleepUnit * 2, result: .success(1)) },
            { try await makeAsync("2", sleep: sleepUnit, result: .success(2)) }
        ])()

        XCTAssertEqual(values, [1, 2],
                       "Should not affect order")
    }

    func testAsyncAll_fail() async throws
    {
        do {
            _ = try await asyncAll([
                { try await makeAsync("1", sleep: sleepUnit, result: .failure(MyError())) },
                { try await makeAsync("2", sleep: sleepUnit * 2, result: .success(2)) }
            ])()

            XCTFail("Should never reach here.")
        }
        catch let error as MyError {
            XCTAssertEqual(error, MyError(), "First arrival should be MyError.")
        }
        catch {
            XCTFail("Should never reach here.")
        }
    }

    func testAsyncAll_sibling_cancelling() async throws
    {
        actor Box {
            var isSiblingCancelled = false

            func toggle() {
                isSiblingCancelled.toggle()
            }
        }

        let box = Box()

        do {
            _ = try await asyncAll([
                { try await makeAsync("1", sleep: sleepUnit, result: .failure(MyError())) },
                {
                    try await withTaskCancellationHandler {
                        try await makeAsync("2", sleep: sleepUnit * 2, result: .success(2))
                    } onCancel: {
                        Task.init { await box.toggle() }
                    }
                }
            ])()

            XCTFail()
        }
        catch let error as MyError {
            XCTAssertEqual(error, MyError(), "First arrival should be MyError.")
        }
        catch {
            XCTFail("Should never reach here.")
        }

        let isSiblingCancelled = await box.isSiblingCancelled
        XCTAssertTrue(isSiblingCancelled, "Should cancel other running asyncs")
    }
}
