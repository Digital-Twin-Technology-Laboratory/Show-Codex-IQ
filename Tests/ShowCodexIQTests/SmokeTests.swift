import XCTest
@testable import ShowCodexIQCore

final class SmokeTests: XCTestCase {
    func testApplicationMetadata() {
        XCTAssertEqual(AppMetadata.displayName, "Show Codex IQ")
        XCTAssertEqual(AppMetadata.bundleIdentifier, "io.github.zzzzzzjw.ShowCodexIQ")
        XCTAssertEqual(AppMetadata.version, "0.1.0-beta.1")
    }
}
