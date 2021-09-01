import XCTest
@testable import FunAsync

final class AsyncFirstSuccessTests: XCTestCase
{
    func testAsyncFirstSuccess() async throws
    {
        let firstSuccess = await asyncFirstSuccess([
            { try await makeAsync("1", sleep: 1, isSuccess: true) },
            { try await makeAsync("2", sleep: 2, isSuccess: true) }
        ])()

        XCTAssertEqual(firstSuccess, 1)
    }

    func testAsyncFirstSuccess_firstFail_secondSuccess() async throws
    {
        let firstSuccess = await asyncFirstSuccess([
            { try await makeAsync("1", sleep: 1, isSuccess: false) },
            { try await makeAsync("2", sleep: 2, isSuccess: true) }
        ])()

        XCTAssertEqual(firstSuccess, 2)
    }

    func testAsyncFirstSuccess_allFail() async throws
    {
        let firstSuccess = await asyncFirstSuccess([
            { try await makeAsync("1", sleep: 1, isSuccess: false) },
            { try await makeAsync("2", sleep: 2, isSuccess: false) }
        ])()

        XCTAssertNil(firstSuccess, "All asyncs have failed.")
    }

    func testAsyncFirstSuccess_sibling_cancelling() async throws
    {
        actor Box {
            var isSiblingCancelled = false

            func toggle() {
                isSiblingCancelled.toggle()
            }
        }

        let box = Box()

        _ = await asyncFirstSuccess([
            { try await makeAsync("1", sleep: 1, isSuccess: true) },
            {
                try await withTaskCancellationHandler {
                    try await makeAsync("2", sleep: 2, isSuccess: true)
                } onCancel: {
                    Task.init { await box.toggle() }
                }
            }
        ])()

        let isSiblingCancelled = await box.isSiblingCancelled
        XCTAssertTrue(isSiblingCancelled, "Race should cancel other running asyncs")
    }
}
