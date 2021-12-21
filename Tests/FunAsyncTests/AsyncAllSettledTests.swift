import XCTest
@testable import FunAsync

final class AsyncAllSettledTests: XCTestCase
{
    func testAsyncAllSettled_success() async throws
    {
        let results = await asyncAllSettled([
            { try await makeAsync("1", sleep: sleepUnit, result: .success(1)) },
            { try await makeAsync("2", sleep: sleepUnit * 2, result: .success(2)) }
        ])()
            .map { $0.mapError(EqError.init) }

        XCTAssertEqual(results, [.success(1), .success(2)])
    }

    func testAsyncAllSettled_success2() async throws
    {
        let results = await asyncAllSettled([
            { try await makeAsync("1", sleep: sleepUnit * 2, result: .success(1)) },
            { try await makeAsync("2", sleep: sleepUnit, result: .success(2)) }
        ])()
            .map { $0.mapError(EqError.init) }

        XCTAssertEqual(results, [.success(1), .success(2)],
                       "Should not affect order")
    }

    func testAsyncAllSettled_fail() async throws
    {
        let results = await asyncAllSettled([
            { try await makeAsync("1", sleep: sleepUnit, result: .failure(MyError())) },
            { try await makeAsync("2", sleep: sleepUnit * 2, result: .success(2)) }
        ])()
            .map { $0.mapError(EqError.init) }

        XCTAssertEqual(results, [.failure(EqError(MyError())), .success(2)])
    }

    func testAsyncAllSettled_fail2() async throws
    {
        let results = await asyncAllSettled([
            { try await makeAsync("1", sleep: sleepUnit * 2, result: .failure(MyError())) },
            { try await makeAsync("2", sleep: sleepUnit, result: .success(2)) }
        ])()
            .map { $0.mapError(EqError.init) }

        XCTAssertEqual(results, [.failure(EqError(MyError())), .success(2)],
                       "Should not affect order")
    }
}
