import PickleCore
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: GameStore
    @State private var showSettings = false
    @State private var showHistory = false
    @State private var confirmNew = false

    var body: some View {
        let s = store.state
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 12) {
                header
                teams(s)
                callCard(s)
                serveCard(s)
                bigButtons(s)
                bottomRow
                Text("ラリー \(s.rallies)").font(Theme.font(12)).foregroundStyle(Theme.muted)
            }
            .padding(.horizontal, 14)
            .padding(.top, 6)
            .padding(.bottom, 4)

            if s.winner != nil {
                GameOverView()
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .animation(.spring(duration: 0.3), value: s.winner)
        .foregroundStyle(Theme.text)
        .sheet(isPresented: $showSettings) { SettingsView().environmentObject(store) }
        .sheet(isPresented: $showHistory) { HistoryView().environmentObject(store) }
        .alert("いまの試合を終えて、新しい試合を始めますか？", isPresented: $confirmNew) {
            Button("始める") { store.newGame() }
            Button("やめる", role: .cancel) {}
        }
        .onAppear {
            guard ScreenshotMode.isOn else { return }
            if ScreenshotMode.screen == "history" { showHistory = true }
            if ScreenshotMode.screen == "settings" { showSettings = true }
        }
    }

    // MARK: parts

    private var header: some View {
        HStack(spacing: 8) {
            Text("おはぎコール")
                .font(Theme.font(26))
                .foregroundStyle(Theme.orange)
                .shadow(color: .white, radius: 0, x: 2, y: 2)
                .shadow(color: .white, radius: 0, x: -2, y: -2)
                .shadow(color: .white, radius: 0, x: 2, y: -2)
                .shadow(color: .white, radius: 0, x: -2, y: 2)
            Spacer()
            Button { showHistory = true } label: {
                Image(systemName: "clock.arrow.circlepath").font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Theme.muted)
                    .frame(width: 42, height: 38)
            }
            .buttonStyle(LipButtonStyle(fill: .white, lip: Theme.lip, corner: 19, depth: 4, foreground: Theme.text))
            .frame(width: 42, height: 38)
            .accessibilityLabel("試合の履歴")
            Button { showSettings = true } label: {
                HStack(spacing: 6) {
                    Text(Labels.rules(store.match.config)).font(Theme.font(14))
                    Image(systemName: "gearshape.fill").foregroundStyle(Theme.muted)
                }
                .padding(.horizontal, 14)
            }
            .buttonStyle(LipButtonStyle(fill: .white, lip: Theme.lip, corner: 19, depth: 4, foreground: Theme.text))
            .fixedSize(horizontal: true, vertical: false)
            .frame(height: 38)
        }
    }

    private func teams(_ s: GameState) -> some View {
        HStack(spacing: 10) {
            ForEach(0..<2, id: \.self) { t in
                let serving = s.winner == nil && s.serving == t
                HStack {
                    Text(Labels.teamNames[t])
                        .font(Theme.font(14))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10).padding(.vertical, 3)
                        .background(Capsule().fill(t == 0 ? Theme.team0 : Theme.team1))
                    Spacer()
                    Text("\(s.score[t])").font(Theme.font(32)).monospacedDigit()
                }
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 18).fill(serving ? Theme.orangeSoft : Theme.card)
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(serving ? Theme.orange : Color.clear, lineWidth: 3))
                        .shadow(color: Theme.lip, radius: 0, x: 0, y: 4)
                )
                .overlay(alignment: .topTrailing) {
                    if serving {
                        HStack(spacing: 4) {
                            Image("dog_ohagi_face").resizable().scaledToFill()
                                .frame(width: 18, height: 18).clipShape(Circle())
                                .background(Circle().fill(.white))
                            Text("サーブ").font(Theme.font(11))
                        }
                        .foregroundStyle(.white)
                        .padding(.leading, 3).padding(.trailing, 9).padding(.vertical, 2)
                        .background(Capsule().fill(Theme.orange).shadow(color: Theme.orangeLip, radius: 0, x: 0, y: 2))
                        .offset(x: -8, y: -12)
                    }
                }
            }
        }
        .padding(.top, 6)
    }

    private func callCard(_ s: GameState) -> some View {
        VStack(spacing: 0) {
            Text(Rules.scoreCall(s))
                .font(Theme.font(120))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.3)
                .padding(.horizontal, 8)
                .padding(.top, 18)
                .id("call-\(store.event?.serial ?? 0)")
                .transition(.scale(scale: 0.94).combined(with: .opacity))
            Group {
                if let ev = store.event {
                    Text(ev.text)
                        .font(Theme.font(15))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14).padding(.vertical, 3)
                        .background(Capsule().fill(ev.kind == .point ? Theme.green : (ev.kind == .change ? Theme.red : Theme.muted)))
                        .id(ev.serial)
                        .transition(.scale(scale: 0.6).combined(with: .opacity))
                } else {
                    Color.clear
                }
            }
            .frame(height: 28)
            .padding(.bottom, 6)
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 22).fill(Theme.card)
                .shadow(color: Theme.lip, radius: 0, x: 0, y: 5)
        )
        .overlay(alignment: .top) {
            Text("いま言うコール")
                .font(Theme.font(15))
                .foregroundStyle(.white)
                .padding(.horizontal, 18).padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 12).fill(Theme.orange)
                    .shadow(color: Theme.orangeLip, radius: 0, x: 0, y: 3))
                .offset(y: -14)
        }
        .animation(.spring(duration: 0.25), value: store.event?.serial)
        .padding(.top, 8)
    }

    private func serveCard(_ s: GameState) -> some View {
        let right = Rules.serveSide(s) == .right
        return HStack(spacing: 12) {
            CourtView(right: right).frame(width: 118, height: 82)
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(Labels.side(s)).font(Theme.font(36)).foregroundStyle(Theme.orange)
                    Text("から サーブ").font(Theme.font(20))
                }
                if let server = Labels.server(s) {
                    Text(server).font(Theme.font(14))
                }
                Text("サーブする人から見た向き").font(Theme.font(11)).foregroundStyle(Theme.muted)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 22).fill(Theme.card).shadow(color: Theme.lip, radius: 0, x: 0, y: 5))
    }

    private func bigButtons(_ s: GameState) -> some View {
        let over = s.winner != nil
        return VStack(spacing: 14) {
            Button { store.play(servingSideWon: true) } label: {
                VStack(spacing: 2) {
                    Text("サーブ側が").font(Theme.font(18))
                    Text("ラリーを取った").font(Theme.font(30))
                }
            }
            .buttonStyle(LipButtonStyle(fill: Theme.green, lip: Theme.greenLip, corner: 26, depth: 7))
            Button { store.play(servingSideWon: false) } label: {
                VStack(spacing: 2) {
                    Text("サーブ側が").font(Theme.font(18))
                    Text("ラリーを落とした").font(Theme.font(30))
                }
            }
            .buttonStyle(LipButtonStyle(fill: Theme.red, lip: Theme.redLip, corner: 26, depth: 7))
        }
        .disabled(over)
        .opacity(over ? 0.45 : 1)
        .frame(minHeight: 220)
        .padding(.top, 4)
    }

    private var bottomRow: some View {
        HStack(spacing: 9) {
            Button { store.undo() } label: { Label("1つ戻す", systemImage: "arrow.uturn.backward").font(Theme.font(15)) }
                .disabled(!store.match.canUndo)
                .opacity(store.match.canUndo ? 1 : 0.45)
            Button { store.toggleVoice() } label: {
                Label(store.voice == "off" ? "読み上げ" : store.voiceName,
                      systemImage: store.voice == "off" ? "speaker.fill" : "speaker.wave.2.fill")
                    .font(Theme.font(15)).lineLimit(1).minimumScaleFactor(0.7)
            }
            Button {
                if store.gameInProgress { confirmNew = true } else { store.newGame() }
            } label: { Label("新しい試合", systemImage: "arrow.clockwise").font(Theme.font(15)).lineLimit(1).minimumScaleFactor(0.7) }
        }
        .buttonStyle(LipButtonStyle(fill: .white, lip: Theme.lip, corner: 16, depth: 4, foreground: Theme.text))
        .frame(height: 50)
        .padding(.top, 4)
    }
}

/// The server's half of the court seen from the server (net at the top).
struct CourtView: View {
    var right: Bool

    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 10).fill(Theme.court)
                RoundedRectangle(cornerRadius: 3).fill(.white.opacity(0.9))
                    .frame(width: w - 12, height: 7).offset(x: 6, y: 6)
                RoundedRectangle(cornerRadius: 3).fill(Theme.courtIn)
                    .overlay(RoundedRectangle(cornerRadius: 3).stroke(.white, lineWidth: 2))
                    .frame(width: w - 20, height: h - 22).offset(x: 10, y: 17)
                // service boxes
                let boxW = (w - 26) / 2, boxH = h - 44
                RoundedRectangle(cornerRadius: 3).fill(right ? Color.clear : Theme.boxOn)
                    .frame(width: boxW, height: boxH).offset(x: 12, y: 36)
                RoundedRectangle(cornerRadius: 3).fill(right ? Theme.boxOn : Color.clear)
                    .frame(width: boxW, height: boxH).offset(x: 14 + boxW, y: 36)
                Rectangle().fill(.white).frame(width: w - 20, height: 2).offset(x: 10, y: 34)
                Rectangle().fill(.white).frame(width: 2, height: h - 39).offset(x: w / 2 - 1, y: 34)
                Text("キッチン").font(Theme.font(8)).foregroundStyle(.white.opacity(0.9))
                    .frame(width: w).offset(y: 21)
                Text("左").font(Theme.font(18)).foregroundStyle(right ? Color.white.opacity(0.85) : Theme.text)
                    .frame(width: boxW, height: boxH).offset(x: 12, y: 36)
                Text("右").font(Theme.font(18)).foregroundStyle(right ? Theme.text : Color.white.opacity(0.85))
                    .frame(width: boxW, height: boxH).offset(x: 14 + boxW, y: 36)
            }
        }
        .accessibilityElement()
        .accessibilityLabel(right ? "右からサーブ" : "左からサーブ")
    }
}

struct GameOverView: View {
    @EnvironmentObject var store: GameStore
    @State private var hop = false

    private static let dogs = ["ohagi", "kinako", "shiratama", "dorayaki", "yokan"]

    var body: some View {
        let s = store.state
        let w = s.winner ?? 0
        let dog = Self.dogs[store.match.id.unicodeScalars.reduce(0) { $0 + Int($1.value) } % Self.dogs.count]
        ZStack {
            Color(hex: 0x4A3426).opacity(0.45).ignoresSafeArea()
            VStack(spacing: 4) {
                Image("dog_\(dog)").resizable().scaledToFit().frame(height: 110)
                    .offset(y: hop ? -14 : 0)
                    .rotationEffect(.degrees(hop ? 3 : -2))
                    .task {
                        // Start hopping after layout, so only the dog moves.
                        try? await Task.sleep(nanoseconds: 300_000_000)
                        withAnimation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true)) { hop = true }
                    }
                    .padding(.top, 14)
                Text("\(Labels.teamNames[w])の勝ち").font(Theme.font(28))
                Text("\(s.score[w])-\(s.score[1 - w])").font(Theme.font(56)).foregroundStyle(Theme.orange).monospacedDigit()
                HStack(spacing: 10) {
                    Button { store.undo() } label: { Label("1つ戻す", systemImage: "arrow.uturn.backward").font(Theme.font(16)) }
                        .buttonStyle(LipButtonStyle(fill: .white, lip: Theme.lip, corner: 16, depth: 4, foreground: Theme.text))
                    Button { store.newGame() } label: { Text("新しい試合").font(Theme.font(16)) }
                        .buttonStyle(LipButtonStyle(fill: Theme.orange, lip: Theme.orangeLip, corner: 16, depth: 4))
                }
                .frame(height: 50)
                .padding(.top, 6)
            }
            .padding(18)
            .frame(maxWidth: 400)
            .background(RoundedRectangle(cornerRadius: 26).fill(Theme.card).shadow(color: Theme.lip, radius: 0, x: 0, y: 6))
            .overlay(alignment: .top) {
                Text("ゲームセット！").font(Theme.font(24)).foregroundStyle(.white)
                    .padding(.horizontal, 22).padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Theme.orange).shadow(color: Theme.orangeLip, radius: 0, x: 0, y: 4))
                    .rotationEffect(.degrees(-3))
                    .offset(y: -22)
            }
            .padding(24)
            .foregroundStyle(Theme.text)
        }
    }
}
