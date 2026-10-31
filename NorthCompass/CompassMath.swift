import Foundation

enum CompassMath {
    static func normalize(_ degrees: Double) -> Double {
        let value = degrees.truncatingRemainder(dividingBy: 360)
        return value < 0 ? value + 360 : value
    }

    /// Signed shortest rotation, so crossing north never spins the dial a full turn.
    static func delta(from: Double, to: Double) -> Double {
        normalize(to - from + 180) - 180
    }

    static func degrees(_ heading: Double) -> Int {
        Int(normalize(heading).rounded()) % 360
    }

    static func cardinal(_ heading: Double) -> String {
        let names = ["北", "东北", "东", "东南", "南", "西南", "西", "西北"]
        return names[Int((normalize(heading) + 22.5) / 45) % 8]
    }
}
