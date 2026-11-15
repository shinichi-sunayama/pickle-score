// Game history and words to read aloud. Port of web/history.js and callTokens in web/voice.js.

import Foundation

public struct GameRecord: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var endedAt: Double // milliseconds since 1970 (same as the web version)
    public var config: GameConfig
    public var results: String
    public var score: [Int]
    public var winner: Int?
    public var rallies: Int

    public init(match: Match, endedAt: Double) {
        let s = match.state
        id = match.id
        self.endedAt = endedAt
        config = match.config
        results = match.results
        score = s.score
        winner = s.winner
        rallies = s.rallies
    }
}

public struct TimelineRow: Equatable, Sendable {
    public let n: Int
    public let call: String
    public let side: CourtSide
    public let serving: Int
    public let winner: Int?
    /// "W"/"L" for the rally played from this call, nil for the state after the last rally.
    public let result: Character?
}

public enum History {
    public static let limit = 30

    public static func upsert(_ list: [GameRecord], _ record: GameRecord, limit: Int = History.limit) -> [GameRecord] {
        Array(([record] + list.filter { $0.id != record.id }).prefix(limit))
    }

    public static func remove(_ list: [GameRecord], id: String) -> [GameRecord] {
        list.filter { $0.id != id }
    }

    /// Rally-by-rally view: the call before each rally and what happened.
    public static func timeline(_ config: GameConfig, _ results: String) -> [TimelineRow] {
        var rows: [TimelineRow] = []
        var state = Rules.newGame(config)
        let chars = Array(results)
        for i in 0...chars.count {
            let result: Character? = i < chars.count ? chars[i] : nil
            rows.append(TimelineRow(n: i + 1, call: Rules.scoreCall(state), side: Rules.serveSide(state),
                                    serving: state.serving, winner: state.winner, result: result))
            if let r = result { state = Rules.playRally(state, servingSideWon: r == "W") }
        }
        return rows
    }
}

/// One word of a spoken call.
public enum CallToken: Equatable, Sendable {
    case phrase(String) // "sideout", "second", "gameset"
    case number(Int)
}

public enum Speech {
    /// Tokens to say for a state: optional phrase first, then the numbers of the call.
    /// When the game is over: "gameset", winner's score, loser's score.
    public static func callTokens(_ state: GameState, phrase: String? = nil) -> [CallToken] {
        if let w = state.winner {
            return [.phrase("gameset"), .number(state.score[w]), .number(state.score[1 - w])]
        }
        let nums = Rules.scoreCall(state).split(separator: "-").compactMap { Int($0) }.map { CallToken.number($0) }
        if let p = phrase, !p.isEmpty { return [.phrase(p)] + nums }
        return nums
    }
}
