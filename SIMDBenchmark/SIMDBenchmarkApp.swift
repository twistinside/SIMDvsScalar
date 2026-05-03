import SwiftUI

@main
struct SIMDBenchmarkApp: App {
    @State private var mcpServerController = SIMDBenchmarkMCPServerController()

    var body: some Scene {
        WindowGroup {
            ContentView(mcpServerController: mcpServerController)
        }
        .windowResizability(.contentSize)
    }
}
