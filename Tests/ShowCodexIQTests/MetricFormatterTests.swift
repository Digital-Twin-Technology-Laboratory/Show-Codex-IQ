import XCTest
@testable import ShowCodexIQCore

final class MetricFormatterTests: XCTestCase {
    func testMetricFormatting() {
        XCTAssertEqual(MetricFormatter.detailValue(105, metric: .iq), "105")
        XCTAssertEqual(MetricFormatter.detailValue(2.429979, metric: .cost), "$2.43")
        XCTAssertEqual(MetricFormatter.detailValue(1_955, metric: .duration), "33 分钟")
        XCTAssertEqual(MetricFormatter.detailValue(82.25, metric: .overall), "82.3")
        XCTAssertEqual(MetricFormatter.menuBarValue(5_103, metric: .duration), "1.4h")
        XCTAssertEqual(MetricFormatter.compactModelName("GPT-5.6 Sol xhigh"), "5.6 Sol xh")
    }
}
