import Foundation
import PickleCore

/// Store screenshots are taken in the cloud with simulators (.github/workflows/screenshots.yml).
/// Launch arguments set up a scene; without them the app behaves normally and nothing is changed.
///   -shotResults <W/L string>   the current game
///   -shotScreen main|over|history|settings|menu
///   -shotVoice <voice id>
enum ScreenshotMode {
    private static let args = ProcessInfo.processInfo.arguments

    static func value(_ key: String) -> String? {
        guard let i = args.firstIndex(of: "-\(key)"), i + 1 < args.count else { return nil }
        return args[i + 1]
    }

    static var isOn: Bool { value("shotResults") != nil }
    static var screen: String { value("shotScreen") ?? "main" }

    /// Two past games for the history screenshot: one finished, one stopped halfway.
    static func sampleHistory() -> [GameRecord] {
        var finished = Match(id: "shot-1")
        var rng: UInt64 = 20_261_115
        while finished.state.winner == nil {
            rng = rng &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            finished = finished.recording(servingSideWon: (rng >> 33) % 100 < 58)
        }
        let halfway = Match(id: "shot-2", results: "WWLWLLWW")
        let base = 1_794_700_000_000.0 // 2026-11 (milliseconds)
        return [GameRecord(match: finished, endedAt: base + 3_600_000), GameRecord(match: halfway, endedAt: base)]
    }
}
