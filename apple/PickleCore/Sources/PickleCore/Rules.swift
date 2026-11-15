// Pickleball score-calling rules (USA Pickleball Official Rulebook 2026). Port of web/core.js.
// See docs/rules.md for the rule references.
//
// Teams are 0 and 1. A game is fully described by its config plus the rally results, where each
// result is "W" (serving side won the rally) or "L" (serving side lost it). Undo = drop the last result.

import Foundation

public enum Players: String, Codable, CaseIterable, Sendable {
    case doubles, singles
}

public enum Scoring: String, Codable, CaseIterable, Sendable {
    case sideout // standard, Rule 4.A
    case rally // Rule 14.A
}

public enum CourtSide: String, Sendable {
    case right, left
}

public struct GameConfig: Codable, Equatable, Hashable, Sendable {
    public var players: Players
    public var scoring: Scoring
    public var target: Int // Rule 15.C: 11, 15 or 21
    public var winBy: Int // Rule 15.C: 2 (1 allowed in team play)
    public var firstServer: Int // team that serves first

    public init(players: Players = .doubles, scoring: Scoring = .sideout, target: Int = 11, winBy: Int = 2, firstServer: Int = 0) {
        self.players = players
        self.scoring = scoring
        self.target = target
        self.winBy = winBy
        self.firstServer = firstServer
    }

    public static let standard = GameConfig()

    public var isValid: Bool {
        target >= 1 && winBy >= 1 && (firstServer == 0 || firstServer == 1)
    }

    var usesServerNumber: Bool { players == .doubles && scoring == .sideout }
}

public struct GameState: Equatable, Sendable {
    public let config: GameConfig
    public internal(set) var score: [Int]
    public internal(set) var serving: Int
    /// 1 or 2 in doubles side-out scoring, nil otherwise.
    public internal(set) var serverNumber: Int?
    /// Doubles only: whether the server is the team's "starter" (the player on the right at 0 points).
    public internal(set) var serverIsStarter: Bool
    public internal(set) var rallies: Int
    public internal(set) var winner: Int?
}

public enum RallyError: Error, Equatable {
    case badResult(Character)
}

public enum Rules {
    // Rule 5.B.3: the starter is on the right when the team score is even, left when odd.
    static func starterOnRight(_ teamScore: Int) -> Bool { teamScore % 2 == 0 }

    public static func newGame(_ config: GameConfig = .standard) -> GameState {
        GameState(
            config: config,
            score: [0, 0],
            serving: config.firstServer,
            // Rule 5.B / 6.B.2: the team that starts the game has only one server, called server 2.
            serverNumber: config.usesServerNumber ? 2 : nil,
            serverIsStarter: true,
            rallies: 0,
            winner: nil
        )
    }

    static func winner(of score: [Int], _ config: GameConfig) -> Int? {
        for t in [0, 1] where score[t] >= config.target && score[t] - score[1 - t] >= config.winBy {
            return t
        }
        return nil
    }

    static func sideOut(_ state: GameState, score: [Int]) -> GameState {
        var next = state
        let serving = 1 - state.serving
        next.score = score
        next.serving = serving
        next.serverNumber = state.config.usesServerNumber ? 1 : nil
        // The new serving team's first server is the player standing on the right (Rule 5.B.2).
        next.serverIsStarter = starterOnRight(score[serving])
        return next
    }

    /// Apply one rally. Rallies after the game ends are ignored.
    public static func playRally(_ state: GameState, servingSideWon: Bool) -> GameState {
        if state.winner != nil { return state }
        let config = state.config
        let s = state.serving
        let r = 1 - s
        var next: GameState

        if servingSideWon {
            // Rule 4.A / 14.A.2: the serving side scores; the same server continues.
            next = state
            next.score[s] += 1
        } else if config.scoring == .rally {
            // Rule 14.A.2 / 14.A.5: the receiving side scores and gets the serve.
            var score = state.score
            score[r] += 1
            next = sideOut(state, score: score)
        } else if config.players == .doubles && state.serverNumber == 1 {
            // Rule 5.B.5: the serve passes to the partner (server 2).
            next = state
            next.serverNumber = 2
            next.serverIsStarter.toggle()
        } else {
            // Rule 5.A.3 / 5.B.6: side out.
            next = sideOut(state, score: state.score)
        }

        next.rallies = state.rallies + 1
        next.winner = winner(of: next.score, config)
        return next
    }

    /// Replay a results string ("W"/"L") from the start.
    public static func replay(_ config: GameConfig, _ results: String) throws -> GameState {
        var state = newGame(config)
        for ch in results {
            switch ch {
            case "W": state = playRally(state, servingSideWon: true)
            case "L": state = playRally(state, servingSideWon: false)
            default: throw RallyError.badResult(ch)
            }
        }
        return state
    }

    /// The score call to say before serving, e.g. "4-2-1" (doubles side-out) or "4-2".
    public static func scoreCall(_ state: GameState) -> String {
        let s = state.score[state.serving]
        let r = state.score[1 - state.serving]
        if let n = state.serverNumber { return "\(s)-\(r)-\(n)" }
        return "\(s)-\(r)"
    }

    /// Which half of the court the server serves from.
    public static func serveSide(_ state: GameState) -> CourtSide {
        let even = state.score[state.serving] % 2 == 0
        if state.config.players == .singles { return even ? .right : .left } // Rule 5.A.1
        // Rule 5.B.3: starter is right on even, partner is right on odd.
        return even == state.serverIsStarter ? .right : .left
    }
}

/// Undo-friendly game record: id + config + results string.
public struct Match: Codable, Equatable, Sendable {
    public var id: String
    public var config: GameConfig
    public var results: String

    public init(id: String = Match.newId(), config: GameConfig = .standard, results: String = "") {
        self.id = id
        self.config = config
        self.results = results
    }

    public static func newId() -> String {
        let ms = Int(Date().timeIntervalSince1970 * 1000)
        let rand = String(Int.random(in: 0..<60_466_176), radix: 36)
        return "\(String(ms, radix: 36))-\(rand)"
    }

    /// Current state. Bad data falls back to a fresh game.
    public var state: GameState {
        (try? Rules.replay(config, results)) ?? Rules.newGame(config)
    }

    public var canUndo: Bool { !results.isEmpty }

    public func recording(servingSideWon: Bool) -> Match {
        if state.winner != nil { return self }
        var m = self
        m.results.append(servingSideWon ? "W" : "L")
        return m
    }

    public func undoing() -> Match {
        var m = self
        if !m.results.isEmpty { m.results.removeLast() }
        return m
    }
}
