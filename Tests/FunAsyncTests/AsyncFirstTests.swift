import XCTest
@testable import FunAsync

final class AsyncFirstTests: XCTestCase
{
    func testNonThrowingAsyncFirst() async throws
    {
        // NOTE: Using `try?` to ignore throwing-function part.
        let first = await asyncFirst([
            { try? await makeAsync("1", sleep: 1, isSuccess: true) },
            { try? await makeAsync("2", sleep: 2, isSuccess: true) }
        ])()

        XCTAssertEqual(first, 1)
    }

    func testAsyncFirst_success() async throws
    {
        let first = try await asyncFirst([
            { try await makeAsync("1", sleep: 1, isSuccess: true) },
            { try await makeAsync("2", sleep: 2, isSuccess: true) }
        ])()

        XCTAssertEqual(first, 1)
    }

    func testAsyncFirst_fail() async throws
    {
        do {
            _ = try await asyncFirst([
                { try await makeAsync("1", sleep: 1, isSuccess: false) },
                { try await makeAsync("2", sleep: 2, isSuccess: true) }
            ])()

            XCTFail("Should never reach here.")
        }
        catch {
            XCTAssertNotNil(error as? MyError, "First arrival should be MyError.")
        }
    }

    func testAsyncFirst_sibling_cancelling() async throws
    {
        actor Box {
            var isSiblingCancelled = false

            func toggle() {
                isSiblingCancelled.toggle()
            }
        }

        let box = Box()

        do {
            _ = try await asyncFirst([
                { try await makeAsync("1", sleep: 1, isSuccess: false) },
                {
                    try await withTaskCancellationHandler {
                        try await makeAsync("2", sleep: 2, isSuccess: true)
                    } onCancel: {
                        Task.init { await box.toggle() }
                    }
                }
            ])()

            XCTFail()
        }
        catch {
            XCTAssertNotNil(error as? MyError)
        }

        let isSiblingCancelled = await box.isSiblingCancelled
        XCTAssertTrue(isSiblingCancelled, "Race should cancel other running asyncs")
    }
}
