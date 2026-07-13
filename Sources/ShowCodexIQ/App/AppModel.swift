import Foundation
import Observation
import ShowCodexIQCore

@MainActor
@Observable
final class AppModel {
    let settings: AppSettings

    private let repository: RadarRepository
    private let scheduler: RefreshScheduler
    private var didStart = false

    var repositoryState: RadarRepositoryState = .empty
    var isRefreshing = false
    var hasLoadedCache = false

    init(
        settings: AppSettings = AppSettings(),
        repository: RadarRepository = RadarRepository(
            client: URLSessionRadarClient(),
            store: SnapshotStore()
        ),
        scheduler: RefreshScheduler = RefreshScheduler()
    ) {
        self.settings = settings
        self.repository = repository
        self.scheduler = scheduler
    }

    var snapshot: RadarSnapshot? { repositoryState.snapshot }
    var costHistory: [CostHistoryPoint] { repositoryState.costHistory }
    var isStale: Bool { repositoryState.isStale }
    var errorMessage: String? { repositoryState.errorMessage }
    var isInitialLoading: Bool { !hasLoadedCache && snapshot == nil }

    var lastSuccessfulRefresh: Date? {
        snapshot?.fetchedAt
    }

    var latestBenchmarkDate: String? {
        snapshot?.benchmarks.compactMap(\.latest?.date).max()
    }

    var menuBarRanking: [RankedModel] {
        rankings(for: settings.menuBarMetric).prefix(2).map { $0 }
    }

    func rankings(for metric: RankingMetric) -> [RankedModel] {
        RankingEngine.rank(
            snapshot?.benchmarks ?? [],
            by: metric,
            weights: settings.rankingWeights
        )
    }

    func start() async {
        guard !didStart else { return }
        didStart = true
        repositoryState = await repository.loadCached()
        hasLoadedCache = true
        await reconfigureScheduler()
        await refreshIfNeeded()
    }

    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        repositoryState = await repository.refresh()
        isRefreshing = false
    }

    func refreshIfNeeded() async {
        let due = RefreshPolicy.isRefreshDue(
            lastSuccessfulRefresh: lastSuccessfulRefresh,
            now: Date(),
            interval: settings.refreshInterval
        )
        if due {
            await refresh()
        }
    }

    func settingsDidChange() {
        Task { await reconfigureScheduler() }
    }

    private func reconfigureScheduler() async {
        let enabled = settings.automaticRefreshEnabled
        let interval = settings.refreshInterval
        await scheduler.configure(enabled: enabled, interval: interval) { [weak self] in
            await self?.refresh()
        }
    }
}
