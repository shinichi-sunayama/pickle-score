import Foundation
import XCTest
@testable import PickleCore

/// Same rule cases as the web tests (tests/cases.json at the repository root).
final class RulesTests: XCTestCase {
    struct CaseConfig: Decodable {
        var players: Players?
        var scoring: Scoring?
        var target: Int?
        var winBy: Int?
        var firstServer: Int?

        var config: GameConfig {
            GameConfig(players: players ?? .doubles, scoring: scoring ?? .sideout,
                       target: target ?? 11, winBy: winBy ?? 2, firstServer: firstServer ?? 0)
        }
    }

    struct Case: Decodable {
        var name: String
        var config: CaseConfig
        var results: String
        var checks: [String: String]
        var winner: Int?
        var rallies: Int
    }

    struct Cases: Decodable {
        var cases: [Case]
    }

    static func loadCases() throws -> [Case] {
        var url = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { url.deleteLastPathComponent() }
        url.appendPathComponent("tests/cases.json")
        return try JSONDecoder().decode(Cases.self, from: Data(contentsOf: url)).cases
    }

    static func describe(_ s: GameState) -> String {
        "\(Rules.scoreCall(s)) \(Rules.serveSide(s) == .right ? "R" : "L") T\(s.serving)"
    }

    func testSharedCases() throws {
        let cases = try Self.loadCases()
        XCTAssertGreaterThanOrEqual(cases.count, 15)
        for c in cases {
            for (at, want) in c.checks {
                let n = Int(at)!
                let s = try Rules.replay(c.config.config, String(c.results.prefix(n)))
                XCTAssertEqual(Self.describe(s), want, "\(c.name) after \(n) rallies")
            }
            let end = try Rules.replay(c.config.config, c.results)
            XCTAssertEqual(end.winner, c.winner, "\(c.name) winner")
            XCTAssertEqual(end.rallies, c.rallies, "\(c.name) rallies")
        }
    }

    func testStartIsZeroZeroTwo() {
        let s = Rules.newGame()
        XCTAssertEqual(Rules.scoreCall(s), "0-0-2")
        XCTAssertEqual(Rules.serveSide(s), .right)
    }

    func testBadResultLetter() {
        XCTAssertThrowsError(try Rules.replay(.standard, "WX"))
    }

    func testMatchRecordUndo() {
        var m = Match(id: "a")
        XCTAssertFalse(m.canUndo)
        m = m.recording(servingSideWon: true).recording(servingSideWon: false)
        XCTAssertEqual(m.results, "WL")
        XCTAssertEqual(Rules.scoreCall(m.state), "0-1-1")
        m = m.undoing()
        XCTAssertEqual(Rules.scoreCall(m.state), "1-0-2")
        XCTAssertEqual(m.undoing().undoing().results, "")
    }

    func testNoRallyAfterWin() {
        var m = Match(id: "a", config: GameConfig(players: .singles))
        for _ in 0..<11 { m = m.recording(servingSideWon: true) }
        XCTAssertEqual(m.state.winner, 0)
        XCTAssertEqual(m.recording(servingSideWon: true).results.count, 11)
        XCTAssertNil(m.undoing().state.winner)
    }

    func testMatchJSONRoundTripMatchesWebFormat() throws {
        let json = #"{"id":"g1","config":{"players":"doubles","scoring":"rally","target":15,"winBy":2,"firstServer":1},"results":"WL"}"#
        let m = try JSONDecoder().decode(Match.self, from: Data(json.utf8))
        XCTAssertEqual(m.config.scoring, .rally)
        XCTAssertEqual(m.config.firstServer, 1)
        let back = try JSONDecoder().decode(Match.self, from: JSONEncoder().encode(m))
        XCTAssertEqual(back, m)
    }

    func testRandomGamesInvariants() {
        var rng = SplitMix(seed: 7)
        for _ in 0..<200 {
            let config = GameConfig(players: rng.next() < 0.5 ? .doubles : .singles,
                                    scoring: rng.next() < 0.5 ? .sideout : .rally,
                                    target: [11, 15, 21][Int(rng.next() * 3)], winBy: rng.next() < 0.8 ? 2 : 1)
            var s = Rules.newGame(config)
            var guardCount = 0
            while s.winner == nil && guardCount < 5000 {
                guardCount += 1
                let prev = s
                s = Rules.playRally(s, servingSideWon: rng.next() < 0.5)
                let gained = s.score[0] + s.score[1] - prev.score[0] - prev.score[1]
                XCTAssertTrue(gained == 0 || gained == 1)
                if config.scoring == .sideout {
                    XCTAssertEqual(s.score[1 - prev.serving], prev.score[1 - prev.serving])
                }
                // Rule 5.B.2 / 14.A.4: right after a doubles side out, the serve starts from the right.
                if config.players == .doubles && s.serving != prev.serving && s.winner == nil {
                    XCTAssertEqual(Rules.serveSide(s), .right)
                }
            }
            guard let w = s.winner else { return XCTFail("game never ended") }
            XCTAssertGreaterThanOrEqual(s.score[w], config.target)
            XCTAssertGreaterThanOrEqual(s.score[w] - s.score[1 - w], config.winBy)
        }
    }

    func testHistory() {
        let m = Match(id: "g1", config: GameConfig(players: .singles), results: String(repeating: "W", count: 11))
        let rec = GameRecord(match: m, endedAt: 1000)
        XCTAssertEqual(rec.score, [11, 0])
        XCTAssertEqual(rec.winner, 0)
        var h = History.upsert([], rec)
        var rec2 = rec
        rec2.endedAt = 2000
        h = History.upsert(h, rec2)
        XCTAssertEqual(h.count, 1)
        XCTAssertEqual(h[0].endedAt, 2000)
        h = History.upsert(h, GameRecord(match: Match(id: "g2", results: "W"), endedAt: 3000))
        XCTAssertEqual(h.map(\.id), ["g2", "g1"])
        XCTAssertNil(h[0].winner)
        XCTAssertEqual(History.remove(h, id: "g1").map(\.id), ["g2"])
        var many: [GameRecord] = []
        for i in 0..<40 {
            var r = rec
            r.id = "x\(i)"
            many = History.upsert(many, r)
        }
        XCTAssertEqual(many.count, 30)
        XCTAssertEqual(many[0].id, "x39")
    }

    func testTimeline() {
        let rows = History.timeline(.standard, "LWL")
        XCTAssertEqual(rows.map { $0.call + ($0.result.map { String($0) } ?? "") }, ["0-0-2L", "0-0-1W", "1-0-1L", "1-0-2"])
        XCTAssertEqual(rows[1].side, .right)
    }

    func testCallTokens() throws {
        XCTAssertEqual(Speech.callTokens(Rules.newGame()), [.number(0), .number(0), .number(2)])
        XCTAssertEqual(Speech.callTokens(try Rules.replay(.standard, "L"), phrase: "sideout"),
                       [.phrase("sideout"), .number(0), .number(0), .number(1)])
        let won = try Rules.replay(GameConfig(players: .singles), "LWWWWWWWWWWW")
        XCTAssertEqual(Speech.callTokens(won), [.phrase("gameset"), .number(11), .number(0)])
    }
}

/// Small deterministic random numbers so test runs are repeatable.
struct SplitMix {
    var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> Double {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        z ^= z >> 31
        return Double(z >> 11) / Double(1 << 53)
    }
}
