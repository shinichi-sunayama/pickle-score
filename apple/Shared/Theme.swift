import SwiftUI

/// Colors and fonts shared by the iPhone and Watch apps (same palette as web/style.css).
enum Theme {
    static let sky = Color(hex: 0xCFE9F7)
    static let sky2 = Color(hex: 0xE8F4E6)
    static let cream = Color(hex: 0xFBF3E4)
    static let card = Color(hex: 0xFFFDF8)
    static let lip = Color(hex: 0xE6D8BF)
    static let text = Color(hex: 0x4A3426)
    static let muted = Color(hex: 0x8A7562)
    static let orange = Color(hex: 0xF39A4C)
    static let orangeLip = Color(hex: 0xC8702A)
    static let orangeSoft = Color(hex: 0xFFE7CC)
    static let green = Color(hex: 0x4F9E45)
    static let greenLip = Color(hex: 0x357530)
    static let red = Color(hex: 0xE2654F)
    static let redLip = Color(hex: 0xB04532)
    static let team0 = Color(hex: 0x4F9E45)
    static let team1 = Color(hex: 0x5B8FD6)
    static let court = Color(hex: 0x7DBB6E)
    static let courtIn = Color(hex: 0x5EA85A)
    static let boxOn = Color(hex: 0xFFD66B)
    static let chip = Color(hex: 0xF2E9D8)

    /// Rounded Japanese font bundled with the app (M PLUS Rounded 1c Bold, SIL OFL 1.1).
    static let fontName = "RoundedMplus1c-Bold" // PostScript name inside MPLUSRounded1c-Bold.ttf

    static func font(_ size: CGFloat) -> Font {
        .custom(fontName, size: size)
    }

    static var background: LinearGradient {
        LinearGradient(stops: [
            .init(color: sky, location: 0),
            .init(color: sky2, location: 0.25),
            .init(color: cream, location: 0.5),
        ], startPoint: .top, endPoint: .bottom)
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: 1)
    }
}

/// Raised button with a darker "lip" under it, pressed down when tapped.
struct LipButtonStyle: ButtonStyle {
    var fill: Color
    var lip: Color
    var corner: CGFloat = 18
    var depth: CGFloat = 5
    var foreground: Color = .white

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        configuration.label
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(fill)
                    .overlay(
                        RoundedRectangle(cornerRadius: corner, style: .continuous)
                            .fill(LinearGradient(colors: [Color.white.opacity(0.22), Color.white.opacity(0)],
                                                 startPoint: .top, endPoint: .center))
                    )
            )
            .background(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(lip)
                    .offset(y: pressed ? 1 : depth)
            )
            .offset(y: pressed ? depth - 1 : 0)
            .animation(.easeOut(duration: 0.08), value: pressed)
    }
}
