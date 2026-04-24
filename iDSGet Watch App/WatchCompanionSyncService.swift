import Foundation
import WatchConnectivity
import DSGetCore

@MainActor
final class WatchCompanionSyncService: NSObject {
    static let shared = WatchCompanionSyncService()

    enum State: Equatable {
        case idle
        case waitingForPhone
        case syncing
        case synced(Date)
        case failed(String)
    }

    private enum Keys {
        static let payload = "watchAuthPayload"
        static let type = "type"
        static let requestAuthSync = "authSyncRequest"
    }

    var state: State = .idle
    var onAuthenticationDidChange: (@MainActor () async -> Void)?

    private let authService: AuthServiceProtocol

    private override init() {
        self.authService = WatchDI.authService
        super.init()
    }

    func activate() {
        guard WCSession.isSupported() else { return }

        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    func requestAuthenticationSync() {
        activate()
        state = .syncing

        let session = WCSession.default
        guard session.isReachable else {
            state = .waitingForPhone
            return
        }

        session.sendMessage([Keys.type: Keys.requestAuthSync], replyHandler: nil) { [weak self] error in
            Task { @MainActor in
                self?.state = .failed(error.localizedDescription)
            }
        }
    }

    private func applyPayloadData(_ data: Data) async {
        do {
            let payload = try JSONDecoder().decode(WatchAuthenticationContext.self, from: data)

            if payload.isAuthenticated {
                if try await authService.validateSession() == nil {
                    _ = try await authService.refreshSession()
                }
                state = .synced(payload.syncedAt)
            } else {
                try? await authService.logout()
                state = .waitingForPhone
            }

            await onAuthenticationDidChange?()
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}

extension WatchCompanionSyncService: WCSessionDelegate {
    #if os(iOS)
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor [weak self] in
            if let error {
                self?.state = .failed(error.localizedDescription)
            } else if activationState == .activated, self?.state == .idle {
                self?.state = .waitingForPhone
            }
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        guard let data = applicationContext[Keys.payload] as? Data else { return }

        Task { @MainActor [weak self] in
            await self?.applyPayloadData(data)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        guard let data = userInfo[Keys.payload] as? Data else { return }

        Task { @MainActor [weak self] in
            await self?.applyPayloadData(data)
        }
    }
}
