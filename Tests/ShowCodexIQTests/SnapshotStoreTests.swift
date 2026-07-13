import Foundation
import XCTest
@testable import ShowCodexIQCore

final class SnapshotStoreTests: XCTestCase {
    func testSaveAndLoadRoundTrip() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let file = directory.appendingPathComponent("latest.json")
        let store = SnapshotStore(fileURL: file)
        let state = StoredRadarState(snapshot: fixtureSnapshot(), costHistory: [])

        try await store.save(state)
        let loaded = try await store.load()

        XCTAssertEqual(loaded, state)
        try? FileManager.default.removeItem(at: directory)
    }

    func testCostHistoryReplacesSameModelAndDate() {
        let old = CostHistoryPoint(modelID: "model", dateKey: "day", costUSD: 10, recordedAt: .distantPast)
        let latest = ModelBenchmark(
            id: "model",
            label: "Model",
            model: "model",
            reasoningEffort: "high",
            latest: BenchmarkRecord(
                date: "day",
                score: 100,
                status: nil,
                passed: nil,
                tasks: nil,
                wallSeconds: 100,
                costUSD: 12
            ),
            recentDays: []
        )

        let merged = CostHistoryBuilder.merging([old], benchmarks: [latest], recordedAt: Date())

        XCTAssertEqual(merged.count, 1)
        XCTAssertEqual(merged[0].costUSD, 12)
    }

    private func fixtureSnapshot() -> RadarSnapshot {
        RadarSnapshot(
            schemaVersion: "2.0",
            sourceMonitoredAt: "2026-07-13T16:30:00+08:00",
            fetchedAt: Date(timeIntervalSince1970: 1_700_000_000),
            benchmarks: [],
            validators: CacheValidators(etag: "etag", lastModified: "date")
        )
    }
}
