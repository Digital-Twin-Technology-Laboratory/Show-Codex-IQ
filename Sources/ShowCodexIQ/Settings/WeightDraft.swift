import Combine
import ShowCodexIQCore

@MainActor
final class WeightDraft: ObservableObject {
    @Published var iq: Int
    @Published var cost: Int
    @Published var duration: Int

    init(weights: RankingWeights) {
        iq = weights.iq
        cost = weights.cost
        duration = weights.duration
    }

    var weights: RankingWeights {
        RankingWeights(iq: iq, cost: cost, duration: duration)
    }

    var total: Int { iq + cost + duration }
    var isValid: Bool { weights.isValid }

    func reset() {
        iq = RankingWeights.default.iq
        cost = RankingWeights.default.cost
        duration = RankingWeights.default.duration
    }
}
