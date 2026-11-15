import PickleCore
import SwiftUI

/// Watch menu: new game, rules, voice and haptics.
struct WatchMenuView: View {
    @EnvironmentObject var store: GameStore
    @Environment(\.dismiss) private var dismiss
    @State private var config = GameConfig.standard
    @State private var confirmNew = false

    var body: some View {
        List {
            Button {
                if store.gameInProgress { confirmNew = true } else { store.newGame(); dismiss() }
            } label: {
                Label("新しい試合", systemImage: "arrow.clockwise")
            }

            Section("ルール") {
                Picker("人数", selection: $config.players) {
                    Text("ダブルス").tag(Players.doubles)
                    Text("シングルス").tag(Players.singles)
                }
                Picker("得点", selection: $config.scoring) {
                    Text("サーブ側だけ").tag(Scoring.sideout)
                    Text("毎ラリー").tag(Scoring.rally)
                }
                Picker("勝ち", selection: $config.target) {
                    Text("11点").tag(11)
                    Text("15点").tag(15)
                    Text("21点").tag(21)
                }
                Picker("点差", selection: $config.winBy) {
                    Text("2点差").tag(2)
                    Text("1点差").tag(1)
                }
                Picker("最初のサーブ", selection: $config.firstServer) {
                    Text("自分たち").tag(0)
                    Text("相手").tag(1)
                }
                if config != store.match.config {
                    Button("このルールで新しい試合") { store.newGame(config: config); dismiss() }
                        .foregroundStyle(Theme.orange)
                }
            }

            Section("読み上げ・振動") {
                Picker("声", selection: Binding(get: { store.voice }, set: { store.setVoice($0); store.previewVoice($0) })) {
                    Text("なし").tag("off")
                    Text("端末の声").tag("ja")
                    Text("英語の声").tag("en")
                    ForEach(store.voices) { v in Text(v.name).tag(v.id) }
                }
                Toggle("振動", isOn: $store.haptics)
            }

            Section {
                ForEach(store.history.prefix(10)) { r in
                    HStack {
                        Text(r.winner != nil ? "\(Labels.teamShort[r.winner ?? 0])の勝ち" : "途中")
                            .font(.footnote)
                        Spacer()
                        Text("\(r.score[0])-\(r.score[1])").font(Theme.font(15)).monospacedDigit()
                    }
                }
                if store.history.isEmpty { Text("まだありません").font(.footnote).foregroundStyle(.secondary) }
            } header: {
                Text("最近の試合")
            }

            Section {
                VStack(alignment: .leading, spacing: 2) {
                    Text("USA Pickleball 公式ルール 2026年版")
                    ForEach(store.voices) { v in Text(v.credit) }
                    Text("フォント：M PLUS Rounded 1c（OFL）")
                    Text("おはぎきなこ工房")
                }
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("メニュー")
        .onAppear { config = store.match.config }
        .alert("いまの試合を終えて、新しい試合を始めますか？", isPresented: $confirmNew) {
            Button("始める") { store.newGame(); dismiss() }
            Button("やめる", role: .cancel) {}
        }
    }
}
