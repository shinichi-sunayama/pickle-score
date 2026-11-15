import PickleCore
import SwiftUI

/// Main Watch screen: the call, where to serve from, and the two buttons.
struct WatchMainView: View {
    @EnvironmentObject var store: GameStore

    var body: some View {
        let s = store.state
        VStack(spacing: 3) {
            HStack(spacing: 4) {
                Text(Labels.side(s)).font(Theme.font(20)).foregroundStyle(Theme.orange)
                Text("から").font(Theme.font(12))
                Spacer(minLength: 2)
                scores(s)
            }
            Text(Rules.scoreCall(s))
                .font(Theme.font(50))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .id("call-\(store.event?.serial ?? 0)")
                .transition(.scale(scale: 0.9).combined(with: .opacity))
            if let ev = store.event, ev.kind == .change {
                Text(ev.text).font(Theme.font(11)).foregroundStyle(Theme.red).lineLimit(1).minimumScaleFactor(0.6)
            } else {
                Text("サーブ側が").font(Theme.font(11)).foregroundStyle(.secondary)
            }
            HStack(spacing: 6) {
                Button { store.play(servingSideWon: true) } label: {
                    Text("取った").font(Theme.font(19))
                }
                .buttonStyle(LipButtonStyle(fill: Theme.green, lip: Theme.greenLip, corner: 16, depth: 4))
                Button { store.play(servingSideWon: false) } label: {
                    Text("落とした").font(Theme.font(19)).minimumScaleFactor(0.7)
                }
                .buttonStyle(LipButtonStyle(fill: Theme.red, lip: Theme.redLip, corner: 16, depth: 4))
            }
            .disabled(s.winner != nil)
            .padding(.bottom, 4)
        }
        .animation(.spring(duration: 0.25), value: store.event?.serial)
        .padding(.horizontal, 4)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { store.undo() } label: { Image(systemName: "arrow.uturn.backward") }
                    .disabled(!store.match.canUndo)
                    .accessibilityLabel("1つ戻す")
            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink { WatchMenuView() } label: { Image(systemName: "ellipsis") }
                    .accessibilityLabel("メニュー")
            }
        }
        .sheet(isPresented: Binding(get: { s.winner != nil }, set: { _ in })) {
            WatchGameOverView().environmentObject(store)
        }
    }

    private func scores(_ s: GameState) -> some View {
        HStack(spacing: 3) {
            ForEach(0..<2, id: \.self) { t in
                let serving = s.winner == nil && s.serving == t
                Text("\(Labels.teamShort[t]) \(s.score[t])")
                    .font(Theme.font(11))
                    .padding(.horizontal, 5).padding(.vertical, 1)
                    .background(Capsule().fill(serving ? Theme.orange : Color.white.opacity(0.15)))
            }
        }
    }
}

struct WatchGameOverView: View {
    @EnvironmentObject var store: GameStore
    @State private var hop = false
    private static let dogs = ["ohagi", "kinako", "shiratama", "dorayaki", "yokan"]

    var body: some View {
        let s = store.state
        let w = s.winner ?? 0
        let dog = Self.dogs[store.match.id.unicodeScalars.reduce(0) { $0 + Int($1.value) } % Self.dogs.count]
        ScrollView {
            VStack(spacing: 4) {
                Image("dog_\(dog)").resizable().scaledToFit().frame(height: 64)
                    .offset(y: hop ? -8 : 0)
                    .animation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true), value: hop)
                    .onAppear { hop = true }
                Text("ゲームセット！").font(Theme.font(14)).foregroundStyle(Theme.orange)
                Text("\(Labels.teamNames[w])の勝ち").font(Theme.font(16))
                Text("\(s.score[w])-\(s.score[1 - w])").font(Theme.font(34)).monospacedDigit()
                Button { store.newGame() } label: { Text("新しい試合").font(Theme.font(15)) }
                    .buttonStyle(LipButtonStyle(fill: Theme.orange, lip: Theme.orangeLip, corner: 14, depth: 3))
                    .frame(height: 40)
                Button { store.undo() } label: { Label("1つ戻す", systemImage: "arrow.uturn.backward").font(Theme.font(13)) }
                    .buttonStyle(.bordered)
            }
        }
    }
}
