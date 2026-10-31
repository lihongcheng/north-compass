import SwiftUI

@main
struct NorthCompassApp: App {
    var body: some Scene {
        WindowGroup {
            CompassView()
                .preferredColorScheme(.dark)
        }
    }
}
