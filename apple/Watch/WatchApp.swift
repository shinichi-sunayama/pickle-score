import SwiftUI

@main
struct PickleCallWatchApp: App {
    @StateObject private var store = GameStore()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                if ScreenshotMode.isOn && ScreenshotMode.screen == "menu" {
                    WatchMenuView() // store screenshot of the menu
                } else {
                    WatchMainView()
                }
            }
            .environmentObject(store)
        }
    }
}
