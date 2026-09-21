import Foundation

/// Runs the model-library scan off the main thread and publishes the newest result.
///
/// The walk reads every served root and measured at ~1 s on a real library, and
/// `AppState.refreshModels()` is reached from UI actions (a section switch, a
/// finished transfer, a picker opening), so it cannot run on the main actor.
@MainActor
final class ModelLibraryRefresher {
    typealias Scan = @Sendable (DownloadManager.LocalScanInputs) -> [LocalModel]
    typealias Apply = @MainActor ([LocalModel]) -> Void

    private var generation = 0
    private var inFlight: Task<Void, Never>?

    /// Returns immediately; `apply` runs on the main actor once the scan lands.
    /// A scan superseded by a newer one is dropped rather than applied.
    func refresh(
        inputs: DownloadManager.LocalScanInputs,
        scan: @escaping Scan = DownloadManager.discoverLocalModels,
        apply: @escaping Apply
    ) {
        generation &+= 1
        let generation = self.generation
        inFlight = Task { [weak self] in
            // Detached: a plain `Task` inherits the main actor and puts the walk back on it.
            let models = await Task.detached(priority: .utility) { scan(inputs) }.value
            guard !Task.isCancelled, let self, self.generation == generation else { return }
            apply(models)
        }
    }
}
