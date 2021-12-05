import XCTest
@testable import FunAsync

final class WithTimeoutTests: XCTestCase
{
    func testWithTimeout() async throws
    {
        do {
            // 50ms timeout, 100ms task.
            let _ = try await withTimeout(nanoseconds: sleepUnit / 2) {
                try? await makeAsync("1", sleep: sleepUnit, result: .success(1))
            }

            XCTFail("Should never reach here")
        }
        catch {
            XCTAssertTrue(error is TimeoutCancellationError)
        }
    }

    func testWithTimeout_noTimeout() async throws
    {
        do {
            // 200ms timeout, 100ms task.
            let value = try await withTimeout(nanoseconds: sleepUnit * 2) {
                try? await makeAsync("1", sleep: sleepUnit, result: .success(1))
            }

            XCTAssertEqual(value, 1)
        }
        catch {
            XCTFail("Should never reach here")
        }
    }
}
