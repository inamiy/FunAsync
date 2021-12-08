import XCTest
@testable import FunAsync

final class AsyncOrTests: XCTestCase
{
    func testAsyncOr_1st_success() async throws
    {
        do {
            let first = try await asyncOr([
                { try await makeAsync("1", sleep: sleepUnit, result: .success(1)) },
                { try await makeAsync("2", sleep: sleepUnit, result: .success(2)) }
            ])()

            XCTAssertEqual(first, 1)
        }
        catch {
            XCTFail()
        }
    }

    func testAsyncOr_2nd_success() async throws
    {
        do {
            let first = try await asyncOr([
                { try await makeAsync("1", sleep: sleepUnit, result: .failure(MyError())) },
                { try await makeAsync("2", sleep: sleepUnit, result: .success(2)) }
            ])()

            XCTAssertEqual(first, 2)
        }
        catch {
            XCTFail()
        }
    }

    func testAsyncOr_both_fail() async throws
    {
        let lastError = MyError(message: "Err2")

        do {
            let _: Int = try await asyncOr([
                { try await makeAsync("1", sleep: sleepUnit, result: .failure(MyError(message: "Err1"))) },
                { try await makeAsync("2", sleep: sleepUnit, result: .failure(lastError)) }
            ])()

            XCTFail()
        }
        catch let error as MyError {
            XCTAssertEqual(error, lastError)
        }
        catch {
            XCTFail()
        }
    }
}
