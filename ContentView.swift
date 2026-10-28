import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                DashboardView()
            }
            .tabItem {
                Label("Home", systemImage: "square.grid.2x2")
            }

            NavigationStack {
                RestoreView()
            }
            .tabItem {
                Label("Restore", systemImage: "arrow.clockwise")
            }

            NavigationStack {
                ToolkitView()
            }
            .tabItem {
                Label("Toolkit", systemImage: "wand.and.stars")
            }

            NavigationStack {
                MobileGestaltView()
            }
            .tabItem {
                Label("Gestalt", systemImage: "slider.horizontal.3")
            }

            NavigationStack {
                AirCardView()
            }
            .tabItem {
                Label("AirCard", systemImage: "creditcard.and.123")
            }
        }
        .toolbarBackground(Color(hex: SBTheme.backgroundHex), for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .background(Color(hex: SBTheme.backgroundHex))
    }
}
