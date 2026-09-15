import XCTest
@testable import Locant

final class SpringTests: XCTestCase {
    // 1
    func testStartsAtZeroAndSettlesAtOne() {
        for spring in [Spring.wake, .settle, .tuck] {
            XCTAssertEqual(spring.value(at: 0), 0)
            XCTAssertEqual(spring.value(at: spring.settleTime), 1, accuracy: 0.01)
            XCTAssertEqual(spring.value(at: spring.settleTime * 2), 1, accuracy: 0.001)
        }
    }

    // 2
    func testUnderDampedOvershootsAndCriticalDoesNot() {
        let samples = stride(from: 0.0, through: 1.0, by: 0.005)
        XCTAssertGreaterThan(samples.map(Spring.wake.value(at:)).max()!, 1.005, "the wake spring overshoots a little")
        let critical = Spring(response: 0.4, damping: 1)
        XCTAssertLessThanOrEqual(samples.map(critical.value(at:)).max()!, 1.0001)
    }

    // 3
    func testProgressIsMonotonicBeforeFirstPeak() {
        let values = stride(from: 0.0, through: 0.2, by: 0.01).map(Spring.wake.value(at:))
        XCTAssertEqual(values, values.sorted())
    }
}
