import Foundation
import PickleCore
import SwiftUI

/// Holds the current game, history and settings, and saves them on this device only.
@MainActor
final class GameStore: ObservableObject {
    @Published private(set) var match: Match
    @Published private(set) var state: GameState
    @Published private(set) var history: [GameRecord]
    @Published private(set) var event: GameEvent?
    @Published var voice: String {
        didSet { player.mode = voice; savePrefs() }
    }
    @Published var haptics: Bool {
        didSet { savePrefs() }
    }

    let player = VoicePlayer()
    private var lastTap = Date.distantPast
    private var serial = 0
    private let defaults = UserDefaults.standard
    private static let tapGuard: TimeInterval = 0.4 // ignore a second tap this soon (prevents double counting)

    private struct Prefs: Codable {
        var voice: String
        var lastVoice: String
        var haptics: Bool
    }
    private var lastVoice = "ja"

    init() {
        let decoder = JSONDecoder()
        var m = Match()
        if let data = UserDefaults.standard.data(forKey: "match"),
           let saved = try? decoder.decode(Match.self, from: data),
           saved.config.isValid, (try? Rules.replay(saved.config, saved.results)) != nil {
            m = saved
        }
        match = m
        state = m.state
        if let data = UserDefaults.standard.data(forKey: "history"),
           let saved = try? decoder.decode([GameRecord].self, from: data) {
            history = Array(saved.prefix(History.limit))
        } else {
            history = []
        }
        var p = Prefs(voice: "off", lastVoice: "ja", haptics: true)
        if let data = UserDefaults.standard.data(forKey: "prefs"),
           let saved = try? decoder.decode(Prefs.self, from: data) {
            p = saved
        }
        voice = p.voice
        haptics = p.haptics
        lastVoice = p.lastVoice
        player.mode = p.voice

        // Store screenshots (simulator only, set by launch arguments): show a prepared scene, stay quiet.
        if let results = ScreenshotMode.value("shotResults") {
            let shot = Match(id: "shot-0", results: results)
            match = shot
            state = shot.state
            history = ScreenshotMode.sampleHistory()
            if !results.isEmpty, let prev = try? Rules.replay(shot.config, String(results.dropLast())) {
                event = GameEvent.describe(prev: prev, next: shot.state, serial: 1)
            }
            if let v = ScreenshotMode.value("shotVoice") { voice = v }
            player.mode = "off"
        }
    }

    var voices: [VoicePlayer.VoiceInfo] { player.voices }
    var voiceName: String { VoicePlayer.modeName(voice, voices: voices) }

    // MARK: actions

    func play(servingSideWon: Bool) {
        let now = Date()
        guard now.timeIntervalSince(lastTap) >= Self.tapGuard else { return }
        lastTap = now
        let prev = state
        guard prev.winner == nil else { return }
        setMatch(match.recording(servingSideWon: servingSideWon))
        if state.winner != nil { saveToHistory() }
        serial += 1
        let ev = GameEvent.describe(prev: prev, next: state, serial: serial)
        event = ev
        if haptics { Haptics.play(state.winner != nil ? .gameOver : (ev.kind == .change ? .change : .point)) }
        player.say(Speech.callTokens(state, phrase: ev.phrase))
    }

    func undo() {
        guard match.canUndo else { return }
        // Undoing the last point of a finished game reopens it, so it leaves the history for now.
        if state.winner != nil {
            history = History.remove(history, id: match.id)
            saveHistory()
        }
        setMatch(match.undoing())
        serial += 1
        event = GameEvent(text: "1つ戻しました", kind: .info, phrase: nil, serial: serial)
        if haptics { Haptics.play(.undo) }
        player.say(Speech.callTokens(state))
    }

    /// Starts a new game. A game stopped halfway is kept in the history too.
    func newGame(config: GameConfig? = nil) {
        saveToHistory()
        setMatch(Match(config: config ?? match.config))
        serial += 1
        event = GameEvent(text: "新しい試合", kind: .info, phrase: nil, serial: serial)
        player.say(Speech.callTokens(state))
    }

    func toggleVoice() {
        if voice == "off" {
            voice = lastVoice
        } else {
            lastVoice = voice
            voice = "off"
        }
        player.say(Speech.callTokens(state))
    }

    func previewVoice(_ mode: String) {
        player.mode = mode
        player.say(Speech.callTokens(state))
        player.mode = voice
    }

    func setVoice(_ mode: String) {
        if mode != "off" { lastVoice = mode }
        voice = mode
    }

    func clearHistory() {
        history = []
        saveHistory()
    }

    var gameInProgress: Bool { match.canUndo && state.winner == nil }

    // MARK: saving

    private func setMatch(_ m: Match) {
        match = m
        state = m.state
        if let data = try? JSONEncoder().encode(m) { defaults.set(data, forKey: "match") }
    }

    private func saveToHistory() {
        guard match.canUndo else { return }
        history = History.upsert(history, GameRecord(match: match, endedAt: Date().timeIntervalSince1970 * 1000))
        saveHistory()
    }

    private func saveHistory() {
        if let data = try? JSONEncoder().encode(history) { defaults.set(data, forKey: "history") }
    }

    private func savePrefs() {
        let p = Prefs(voice: voice, lastVoice: lastVoice, haptics: haptics)
        if let data = try? JSONEncoder().encode(p) { defaults.set(data, forKey: "prefs") }
    }
}
