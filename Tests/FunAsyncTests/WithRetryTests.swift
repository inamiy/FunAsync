import XCTest
@testable import FunAsync

final class WithRetryTests: XCTestCase
{
    func testRetry() async throws
    {
        let maxCount: UInt64 = 5
        var count = 0

        let value = try await withRetry(maxCount: maxCount) { () async throws -> Int in
            count += 1
            if count < maxCount {
                return try await makeAsync("\(count)", sleep: sleepUnit, result: .failure(MyError())) as Int
            }
            else {
                return try await makeAsync("\(count)", sleep: sleepUnit, result: .success(count))
            }
        }

        XCTAssertEqual(value, count)
    }

    func testRetry_exponentialBackoff() async throws
    {
        let initialExponentialBackoffNanoseconds: UInt64 = 1 // = 1_000_000_000
        let maxCount: UInt64 = 5
        var count = 0

        let value = try await withRetry(
            maxCount: maxCount,
            delay: { UInt64(pow(2, (Double($1) - 1))) * initialExponentialBackoffNanoseconds },
            run: { () async throws -> Int in
                count += 1
                if count < maxCount {
                    return try await makeAsync("\(count)", sleep: sleepUnit, result: .failure(MyError())) as Int
                }
                else {
                    return try await makeAsync("\(count)", sleep: sleepUnit, result: .success(count))
                }
            }
        )

        XCTAssertEqual(value, count)
    }
}
