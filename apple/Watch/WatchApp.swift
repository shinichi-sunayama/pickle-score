import SwiftUI

@main
struct PickleCallWatchApp: App {
    @StateObject private var store = GameStore()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                WatchMainView()
            }
            .environmentObject(store)
        }
    }
}
