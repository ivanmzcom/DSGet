#if os(iOS)
import Foundation
import WatchConnectivity
import DSGetCore

@MainActor
final class PhoneWatchSyncService: NSObject {
    static let shared = PhoneWatchSyncService()

    private enum Keys {
        static let payload = "watchAuthPayload"
        static let type = "type"
        static let requestAuthSync = "authSyncRequest"
    }

    private let authService: AuthServiceProtocol

    private override init() {
        self.authService = DIService.authService
        super.init()
    }

    func activate() {
        guard WCSession.isSupported() else { return }

        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    func syncAuthentication() async {
        let payload = await currentPayload()
        push(payload)
    }

    func clearAuthentication() {
        push(.loggedOut)
    }

    private func currentPayload() async -> WatchAuthenticationContext {
        await authService.isLoggedIn() ? .authenticated : .loggedOut
    }

    private func push(_ payload: WatchAuthenticationContext) {
        guard WCSession.isSupported() else { return }

        do {
            let data = try JSONEncoder().encode(payload)
            let context: [String: Any] = [Keys.payload: data]

            try WCSession.default.updateApplicationContext(context)
            WCSession.default.transferUserInfo(context)
        } catch {
            #if DEBUG
            print("[PhoneWatchSyncService] Sync failed: \(error)")
            #endif
        }
    }
}

extension PhoneWatchSyncService: WCSessionDelegate {
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        guard error == nil else { return }

        Task { @MainActor [weak self] in
            await self?.syncAuthentication()
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard message[Keys.type] as? String == Keys.requestAuthSync else { return }

        Task { @MainActor [weak self] in
            await self?.syncAuthentication()
        }
    }
}
#endif
