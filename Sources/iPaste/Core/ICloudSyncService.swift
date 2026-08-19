import Foundation

@MainActor
final class ICloudSyncService: ObservableObject {
    enum Status: Equatable {
        case off
        case connecting
        case ready
        case unavailable
        case failed(String)

        var label: String {
            switch self {
            case .off:             return "Off"
            case .connecting:      return "Connecting…"
            case .ready:           return "Synced through iCloud Drive"
            case .unavailable:     return "Requires an Apple-signed build with iCloud entitlement"
            case .failed(let text): return text
            }
        }
    }

    @Published private(set) var status: Status = .off

    private let store: ClipStore
    private var timer: Timer?

    init(store: ClipStore) {
        self.store = store
    }

    func setEnabled(_ enabled: Bool) {
        timer?.invalidate()
        timer = nil

        guard enabled else {
            store.disableICloudSync()
            status = .off
            return
        }

        status = .connecting
        guard let container = FileManager.default.url(forUbiquityContainerIdentifier: nil) else {
            status = .unavailable
            return
        }

        let directory = container
            .appendingPathComponent("Documents", isDirectory: true)
            .appendingPathComponent("iPaste", isDirectory: true)
        do {
            try store.enableICloudSync(at: directory)
            status = .ready
            let timer = Timer(timeInterval: 12, repeats: true) { [weak self] _ in
                MainActor.assumeIsolated {
                    guard let self else { return }
                    do {
                        try self.store.mergeICloudSnapshot()
                        self.status = .ready
                    } catch {
                        self.status = .failed("Sync failed: \(error.localizedDescription)")
                    }
                }
            }
            RunLoop.main.add(timer, forMode: .common)
            self.timer = timer
        } catch {
            status = .failed("Sync failed: \(error.localizedDescription)")
        }
    }
}
