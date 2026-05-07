import SwiftUI
import WixPulseCore

@main
struct WixPulseApp: App {
    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .frame(minWidth: 780, minHeight: 520)
                .task { await store.bootstrap() }
        }
        .windowResizability(.contentSize)

        Settings {
            SettingsView()
                .environmentObject(store)
                .frame(width: 480, height: 360)
        }
    }
}
