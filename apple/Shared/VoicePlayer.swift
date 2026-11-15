import AVFoundation
import Foundation
import PickleCore

/// Reads the score call aloud. Numbers are read in English (0-0-2 = "zero zero two").
/// Modes: "off", "ja" (device voice reading katakana), "en" (device English voice),
/// or a VOICEVOX voice id whose clips are bundled in voices/<id>/ (from web/voices).
final class VoicePlayer: NSObject, AVAudioPlayerDelegate {
    struct VoiceInfo: Decodable, Identifiable, Hashable {
        let id: String
        let name: String
        let credit: String
    }

    private struct Words: Decodable {
        let numbers: [String]
        let phrases: [String: String]
    }

    private static let enPhrases = ["sideout": "side out", "second": "second server", "gameset": "game"]

    let voices: [VoiceInfo]
    private let words: Words?
    private let synth = AVSpeechSynthesizer()
    private var player: AVAudioPlayer?
    private var queue: [URL] = []
    var mode = "off"

    override init() {
        let bundle = Bundle.main
        if let url = bundle.url(forResource: "voices", withExtension: "json", subdirectory: "voices"),
           let data = try? Data(contentsOf: url),
           let list = try? JSONDecoder().decode([VoiceInfo].self, from: data) {
            voices = list
        } else {
            voices = []
        }
        if let url = bundle.url(forResource: "voice-words", withExtension: "json"),
           let data = try? Data(contentsOf: url) {
            words = try? JSONDecoder().decode(Words.self, from: data)
        } else {
            words = nil
        }
        super.init()
    }

    static func modeName(_ mode: String, voices: [VoiceInfo]) -> String {
        switch mode {
        case "off": return "なし"
        case "ja": return "端末の声"
        case "en": return "英語の声"
        default: return voices.first { $0.id == mode }?.name ?? "端末の声"
        }
    }

    private func activateSession() {
        #if os(iOS)
        // Play even when the silent switch is on, and lower music while speaking.
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif
    }

    func stop() {
        queue.removeAll()
        player?.stop()
        player = nil
        if synth.isSpeaking { synth.stopSpeaking(at: .immediate) }
    }

    func say(_ tokens: [CallToken]) {
        stop()
        guard mode != "off" else { return }
        activateSession()
        if voices.contains(where: { $0.id == mode }), let urls = clipURLs(tokens) {
            queue = urls
            playNext()
            return
        }
        speakDevice(english: mode == "en", tokens)
    }

    private func clipURLs(_ tokens: [CallToken]) -> [URL]? {
        var urls: [URL] = []
        for t in tokens {
            let name: String
            switch t {
            case .number(let n): name = "n\(n)"
            case .phrase(let p): name = p
            }
            guard let url = Bundle.main.url(forResource: name, withExtension: "wav", subdirectory: "voices/\(mode)") else {
                return nil // e.g. a score beyond the clip range: use the device voice instead
            }
            urls.append(url)
        }
        return urls
    }

    private func playNext() {
        guard !queue.isEmpty else { player = nil; return }
        let url = queue.removeFirst()
        guard let p = try? AVAudioPlayer(contentsOf: url) else { playNext(); return }
        p.delegate = self
        p.prepareToPlay()
        player = p
        p.play()
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        guard player === self.player else { return }
        playNext()
    }

    private func speakDevice(english: Bool, _ tokens: [CallToken]) {
        let text: String
        if english {
            text = tokens.map { t -> String in
                switch t {
                case .number(let n): return String(n)
                case .phrase(let p): return Self.enPhrases[p] ?? p
                }
            }.joined(separator: ", ")
        } else {
            text = tokens.map { t -> String in
                switch t {
                case .number(let n):
                    if let w = words, n < w.numbers.count { return w.numbers[n] }
                    return String(n)
                case .phrase(let p):
                    return (words?.phrases[p] ?? p) + "。"
                }
            }.joined(separator: "、").replacingOccurrences(of: "。、", with: "。")
        }
        let u = AVSpeechUtterance(string: text)
        u.voice = AVSpeechSynthesisVoice(language: english ? "en-US" : "ja-JP")
        u.rate = AVSpeechUtteranceDefaultSpeechRate * 1.05
        synth.speak(u)
    }
}
