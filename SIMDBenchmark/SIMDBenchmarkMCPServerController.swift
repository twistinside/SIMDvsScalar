import Foundation
import Observation

@MainActor
@Observable
final class SIMDBenchmarkMCPServerController {
    private static let enabledKey = "SIMDBenchmarkMCPServerEnabled"

    private let defaults: UserDefaults
    private let server: SIMDBenchmarkMCPHTTPServer
    private var isApplyingEnabledState = false

    var isEnabled: Bool {
        didSet {
            guard !isApplyingEnabledState, isEnabled != oldValue else {
                return
            }

            applyEnabledState(isEnabled, persist: true)
        }
    }

    var isListening = false
    var errorMessage: String?

    var endpointURL: String {
        server.endpointURL
    }

    var statusText: String {
        if errorMessage != nil {
            return "Failed"
        }

        return isListening ? endpointURL : "Off"
    }

    init(defaults: UserDefaults = .standard, startPersistedServer: Bool = true) {
        self.defaults = defaults
        self.server = SIMDBenchmarkMCPHTTPServer()
        self.isEnabled = defaults.bool(forKey: Self.enabledKey)

        if startPersistedServer {
            applyEnabledState(isEnabled, persist: false)
        }
    }

    func stop() {
        applyEnabledState(false, persist: true)
    }

    private func applyEnabledState(_ enabled: Bool, persist: Bool) {
        if enabled {
            do {
                try server.start()
                isListening = true
                errorMessage = nil

                if persist {
                    defaults.set(true, forKey: Self.enabledKey)
                }
            } catch {
                server.stop()
                isListening = false
                errorMessage = error.localizedDescription

                isApplyingEnabledState = true
                isEnabled = false
                isApplyingEnabledState = false

                defaults.set(false, forKey: Self.enabledKey)
            }
        } else {
            server.stop()
            isListening = false
            errorMessage = nil

            isApplyingEnabledState = true
            isEnabled = false
            isApplyingEnabledState = false

            if persist {
                defaults.set(false, forKey: Self.enabledKey)
            }
        }
    }
}
