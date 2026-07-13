import Foundation
import ShowCodexIQCore

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fatalError("Verification failed: \(message)")
    }
}

require(AppMetadata.displayName == "Show Codex IQ", "display name")
require(AppMetadata.bundleIdentifier == "io.github.zzzzzzjw.ShowCodexIQ", "bundle identifier")
require(AppMetadata.version == "0.1.0-beta.1", "version")

let fixtureURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("Tests/ShowCodexIQTests/Fixtures/current-v2.json")
let fixture = try Data(contentsOf: fixtureURL)
let response = try JSONDecoder().decode(RadarResponse.self, from: fixture)
require(response.benchmarks.count == 3, "fixture benchmark count")
require(RankingEngine.rank(response.benchmarks, by: .iq).first?.id == "gpt_56_sol_xhigh", "IQ ranking")
require(RankingEngine.rank(response.benchmarks, by: .cost).first?.id == "gpt_56_luna_medium", "cost ranking")

let qualityWeights = RankingWeights(iq: 100, cost: 0, duration: 0)
require(qualityWeights.isValid, "custom weights")
require(
    RankingEngine.rank(response.benchmarks, by: .overall, weights: qualityWeights).first?.id == "gpt_56_sol_xhigh",
    "weighted overall ranking"
)

print("✓ Core model and ranking verification passed")
