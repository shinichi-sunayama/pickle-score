import PickleCore
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: GameStore
    @Environment(\.dismiss) private var dismiss
    @State private var config = GameConfig.standard
    @State private var voice = "off"
    @State private var haptics = true
    @State private var confirmRules = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("人数", selection: $config.players) {
                        Text("ダブルス").tag(Players.doubles)
                        Text("シングルス").tag(Players.singles)
                    }
                    Picker("得点のしかた", selection: $config.scoring) {
                        Text("サーブ側だけ（ふつう）").tag(Scoring.sideout)
                        Text("毎ラリー").tag(Scoring.rally)
                    }
                    Picker("勝ち", selection: $config.target) {
                        Text("11点").tag(11)
                        Text("15点").tag(15)
                        Text("21点").tag(21)
                    }
                    .pickerStyle(.segmented)
                    Picker("点差", selection: $config.winBy) {
                        Text("2点差（ふつう）").tag(2)
                        Text("1点差").tag(1)
                    }
                    .pickerStyle(.segmented)
                    Picker("最初にサーブ", selection: $config.firstServer) {
                        Text("自分たち").tag(0)
                        Text("相手").tag(1)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("ルール")
                } footer: {
                    Text("ルールを変えると、新しい試合になります。")
                }

                Section {
                    Picker("声", selection: $voice) {
                        Text("なし").tag("off")
                        Text("端末の声").tag("ja")
                        Text("英語の声").tag("en")
                        ForEach(store.voices) { v in Text(v.name).tag(v.id) }
                    }
                    .onChange(of: voice) { _, new in store.previewVoice(new) }
                    Toggle("ボタンを押したら振動", isOn: $haptics)
                } header: {
                    Text("読み上げ・振動")
                } footer: {
                    Text("数字は英語で読みます（0-0-2 は「ゼロ・ゼロ・ツー」）。マナーモードでも鳴ります。")
                }

                Section("このアプリについて") {
                    Text("ルールは USA Pickleball 公式ルールブック 2026年版にもとづきます。データはこの端末の中だけに保存し、外には送りません。")
                    VStack(alignment: .leading, spacing: 4) {
                        Text("フォント：M PLUS Rounded 1c（SIL Open Font License 1.1）")
                        ForEach(store.voices) { v in Text(v.credit) }
                    }
                    HStack(alignment: .bottom, spacing: 4) {
                        Image("dog_ohagi").resizable().scaledToFit().frame(height: 40)
                        Image("dog_kinako").resizable().scaledToFit().frame(height: 40)
                        Text("おはぎきなこ工房  v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")")
                            .padding(.leading, 6)
                    }
                }
                .font(.footnote)
                .foregroundStyle(Theme.muted)
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("やめる") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("決定") { save() } }
            }
            .alert("ルールを変えると新しい試合になります。よろしいですか？", isPresented: $confirmRules) {
                Button("新しい試合にする") { apply(newRules: true) }
                Button("やめる", role: .cancel) {}
            }
        }
        .onAppear {
            config = store.match.config
            voice = store.voice
            haptics = store.haptics
        }
    }

    private func save() {
        if config != store.match.config {
            if store.gameInProgress { confirmRules = true } else { apply(newRules: true) }
        } else {
            apply(newRules: false)
        }
    }

    private func apply(newRules: Bool) {
        store.setVoice(voice)
        store.haptics = haptics
        if newRules { store.newGame(config: config) }
        dismiss()
    }
}
