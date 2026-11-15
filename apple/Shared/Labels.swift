import PickleCore

/// Japanese labels shared by the screens.
enum Labels {
    static let teamNames = ["自分たち", "相手"]
    static let teamShort = ["自分", "相手"]

    static func rules(_ c: GameConfig) -> String {
        var parts = [c.players == .doubles ? "ダブルス" : "シングルス"]
        if c.scoring == .rally { parts.append("毎ラリー") }
        parts.append("\(c.target)点\(c.winBy == 1 ? "（1点差）" : "")")
        return parts.joined(separator: "・")
    }

    static func server(_ s: GameState) -> String? {
        guard s.config.players == .doubles else { return nil }
        let who = s.serverIsStarter ? "開始時に右の人" : "開始時に左の人"
        if let n = s.serverNumber { return "サーバー\(n)：\(who)" }
        return "サーバー：\(who)"
    }

    static func side(_ s: GameState) -> String {
        Rules.serveSide(s) == .right ? "右" : "左"
    }
}

/// What just happened, for the small message, voice and haptics.
struct GameEvent: Equatable {
    enum Kind { case point, change, info }
    var text: String
    var kind: Kind
    var phrase: String?
    var serial: Int // changes every time, so the same message animates again

    static func describe(prev: GameState, next: GameState, serial: Int) -> GameEvent {
        if next.winner != nil { return GameEvent(text: "ゲームセット", kind: .change, phrase: "gameset", serial: serial) }
        if next.serving != prev.serving {
            let receiverScored = next.score[next.serving] != prev.score[next.serving]
            return GameEvent(text: receiverScored ? "レシーブ側に得点・サーブ交代" : "サイドアウト（サーブ交代）",
                             kind: .change, phrase: "sideout", serial: serial)
        }
        if next.serverNumber != prev.serverNumber {
            return GameEvent(text: "2人目のサーバーへ", kind: .change, phrase: "second", serial: serial)
        }
        return GameEvent(text: "得点！", kind: .point, phrase: nil, serial: serial)
    }
}
