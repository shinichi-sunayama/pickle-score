#if os(watchOS)
import WatchKit
#else
import UIKit
#endif

/// Small vibrations on taps. The Apple Watch taps the wrist, which is easy to feel during play.
enum Haptics {
    enum Kind { case point, change, undo, gameOver }

    static func play(_ kind: Kind) {
        #if os(watchOS)
        let device = WKInterfaceDevice.current()
        switch kind {
        case .point: device.play(.click)
        case .change: device.play(.directionDown)
        case .undo: device.play(.retry)
        case .gameOver: device.play(.success)
        }
        #else
        switch kind {
        case .point: UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .change: UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .undo: UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .gameOver: UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        #endif
    }
}
