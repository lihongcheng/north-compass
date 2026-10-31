import Foundation

func near(_ actual: Double, _ expected: Double) { precondition(abs(actual - expected) < 0.000001, "\(actual) != \(expected)") }
near(CompassMath.delta(from: 359, to: 1), 2)
near(CompassMath.delta(from: 1, to: 359), -2)
near(CompassMath.delta(from: 725, to: 355), -10)
near(CompassMath.delta(from: 0, to: 180), -180)
near(CompassMath.normalize(-721), 359)
precondition(CompassMath.degrees(359.9) == 0)
precondition(CompassMath.cardinal(359.9) == "北")
precondition(CompassMath.cardinal(22.49) == "北")
precondition(CompassMath.cardinal(22.5) == "东北")
precondition(CompassMath.cardinal(337.5) == "北")
var combinations = 0
for start in stride(from: -720.0, through: 720.0, by: 7) {
    for end in stride(from: 0.0, to: 360.0, by: 11) {
        let change = CompassMath.delta(from: start, to: end)
        precondition(change >= -180 && change < 180)
        near(CompassMath.normalize(start + change), CompassMath.normalize(end))
        combinations += 1
    }
}
print("PASS: north crossing, turn direction, multi-turn rotation, cardinal boundaries (\(combinations) combinations)")
