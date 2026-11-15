import SwiftUI

@main
struct PickleCallApp: App {
    @StateObject private var store = GameStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .onAppear { UIApplication.shared.isIdleTimerDisabled = true } // keep the screen on during play
        }
    }
}
