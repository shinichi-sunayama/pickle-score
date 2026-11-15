import PickleCore
import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var store: GameStore
    @Environment(\.dismiss) private var dismiss
    @State private var confirmClear = false
    // The screenshot shows the short game opened.
    @State private var opened: Set<String> = ScreenshotMode.isOn ? ["shot-2"] : []

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "M/d HH:mm"
        return f
    }()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if store.history.isEmpty {
                        Text("まだ試合の記録はありません").foregroundStyle(Theme.muted)
                    }
                    ForEach(store.history) { r in
                        DisclosureGroup(isExpanded: Binding(
                            get: { opened.contains(r.id) },
                            set: { if $0 { opened.insert(r.id) } else { opened.remove(r.id) } }
                        )) {
                            ForEach(History.timeline(r.config, r.results), id: \.n) { row in
                                HStack(spacing: 8) {
                                    Text(row.result == nil ? "" : "\(row.n)").font(.caption).foregroundStyle(Theme.muted)
                                        .frame(width: 26, alignment: .leading)
                                    Text(row.call).font(Theme.font(16)).monospacedDigit().frame(width: 70, alignment: .leading)
                                    rowResult(row)
                                    Spacer(minLength: 0)
                                }
                            }
                        } label: {
                            summary(r)
                        }
                    }
                } footer: {
                    Text("終わった試合と途中でやめた試合を、新しい順に最大30件この端末に残します。試合を押すと、ラリーごとのコール（サーブ側の点から言う形）を確かめられます。")
                }
            }
            .navigationTitle("試合の履歴")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("閉じる") { dismiss() } }
                ToolbarItem(placement: .bottomBar) {
                    Button("履歴を消す", role: .destructive) { confirmClear = true }.disabled(store.history.isEmpty)
                }
            }
            .alert("試合の履歴をすべて消しますか？（もとに戻せません）", isPresented: $confirmClear) {
                Button("消す", role: .destructive) { store.clearHistory() }
                Button("やめる", role: .cancel) {}
            }
        }
    }

    private func summary(_ r: GameRecord) -> some View {
        let finished = r.winner != nil
        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(Self.formatter.string(from: Date(timeIntervalSince1970: r.endedAt / 1000)))  \(Labels.rules(r.config))")
                    .font(.caption).foregroundStyle(Theme.muted)
                Text(finished ? "\(Labels.teamNames[r.winner ?? 0])の勝ち" : "途中まで").font(Theme.font(17))
            }
            Spacer()
            Text("\(r.score[0])-\(r.score[1])").font(Theme.font(24)).monospacedDigit()
                .foregroundStyle(finished ? Theme.orange : Theme.muted)
        }
    }

    @ViewBuilder
    private func rowResult(_ row: TimelineRow) -> some View {
        switch row.result {
        case .some("W"):
            Text("\(Labels.teamNames[row.serving])がサーブで取った").font(.subheadline).foregroundStyle(Theme.green)
        case .some("L"):
            Text("\(Labels.teamNames[row.serving])がサーブで落とした").font(.subheadline).foregroundStyle(Theme.red)
        default:
            Text(row.winner != nil ? "ゲームセット" : "ここで終了").font(.subheadline).foregroundStyle(Theme.muted)
        }
    }
}
