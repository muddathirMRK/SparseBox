import SwiftUI

@main
struct SparseBoxApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .tint(SBTheme.accent)
        }
    }
}
