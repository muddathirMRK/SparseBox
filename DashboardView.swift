import SwiftUI
import UIKit

struct DashboardView: View {
    @State private var showAbout = false

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 19) {
                header

                SBCard {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(UIDevice.current.model.uppercased())
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .tracking(1)
                                .foregroundStyle(Color(hex: SBTheme.accentHex))
                            Text("Device toolbox")
                                .font(.system(size: 22, weight: .bold))
                            Text("Local session · connection health available")
                                .font(.system(size: 12))
                                .foregroundStyle(Color(hex: SBTheme.mutedHex))
                        }
                        Spacer()
                        Image(systemName: "cpu")
                            .font(.system(size: 23, weight: .light))
                            .foregroundStyle(Color(hex: SBTheme.accentHex))
                            .frame(width: 49, height: 49)
                            .background(Color(hex: SBTheme.accentHex).opacity(0.10))
                            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                    }
                    Divider().overlay(Color(hex: SBTheme.borderHex))
                    HStack(spacing: 17) {
                        SBMetric(value: UIDevice.current.systemVersion, label: "iOS")
                        SBMetric(value: appVersion, label: "App version")
                        SBMetric(value: "OFFLINE", label: "Bridge", color: SBTheme.warningHex)
                    }
                }

                SBStatusBanner(
                    title: "UI build · safe mode",
                    message: "The screens, local file imports and export tools work. Restore execution and privileged device inspection require a compatible external bridge that is not bundled in this starter project.",
                    tone: .warning,
                    symbol: "wrench.and.screwdriver"
                )

                SBSectionTitle(title: "Toolbox", subtitle: "Quick access to the main modules")
                VStack(spacing: 0) {
                    NavigationLink(destination: RestoreView()) {
                        SBToolRow(title: "Restore workflows", subtitle: "SparseRestore and BookRestore status", symbol: "arrow.clockwise", trailing: "2 METHODS")
                    }
                    .buttonStyle(.plain)
                    Divider().overlay(Color(hex: SBTheme.borderHex))
                    NavigationLink(destination: ConnectionHealthView()) {
                        SBToolRow(title: "Connection health", subtitle: "Pairing, tunnel and helper validity", symbol: "checkmark.shield", trailing: "CHECK")
                    }
                    .buttonStyle(.plain)
                    Divider().overlay(Color(hex: SBTheme.borderHex))
                    NavigationLink(destination: AFCBrowserView()) {
                        SBToolRow(title: "AFC file browser", subtitle: "Browse a folder imported from Files", symbol: "folder.badge.gearshape", trailing: "LOCAL")
                    }
                    .buttonStyle(.plain)
                    Divider().overlay(Color(hex: SBTheme.borderHex))
                    NavigationLink(destination: InstalledAppsView()) {
                        SBToolRow(title: "Installed apps", subtitle: "Import a paired-device app inventory", symbol: "square.grid.3x3", trailing: "JSON")
                    }
                    .buttonStyle(.plain)
                    Divider().overlay(Color(hex: SBTheme.borderHex))
                    NavigationLink(destination: ProvisioningProfilesView()) {
                        SBToolRow(title: "Provisioning profiles", subtitle: "Import and inspect local profile metadata", symbol: "person.text.rectangle", trailing: "LOCAL")
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .background(Color(hex: SBTheme.surfaceHex))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color(hex: SBTheme.borderHex), lineWidth: 1)
                }

                SBSectionTitle(title: "Important")
                VStack(alignment: .leading, spacing: 8) {
                    Label("Back up before any restore workflow.", systemImage: "externaldrive.badge.exclamationmark")
                    Label("MobileGestalt entries are drafts; nothing is applied by this build.", systemImage: "slider.horizontal.3")
                    Label("Stock iOS does not expose system-wide process or app listings to ordinary apps.", systemImage: "lock.shield")
                }
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: SBTheme.mutedHex))
                .padding(.horizontal, 2)
            }
            .padding(16)
            .padding(.bottom, 20)
        }
        .background(Color(hex: SBTheme.backgroundHex).ignoresSafeArea())
        .navigationBarHidden(true)
        .sheet(isPresented: $showAbout) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("SparseBox is an expandable on-device toolbox UI.")
                            .font(.system(size: 19, weight: .bold))
                        Text("This project intentionally separates UI from privileged device operations. The extension points are designed for a future, version-aware bridge implementation. It does not contain restore exploit code or claim unsupported access.")
                            .font(.system(size: 14))
                            .foregroundStyle(Color(hex: SBTheme.mutedHex))
                        Link("Apple file-system sandbox documentation", destination: URL(string: "https://developer.apple.com/documentation/foundation/using-the-file-system-effectively")!)
                        Link("SparseBox upstream compatibility notes", destination: URL(string: "https://github.com/khanhduytran0/SparseBox")!)
                    }
                    .padding(20)
                }
                .background(Color(hex: SBTheme.backgroundHex).ignoresSafeArea())
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { showAbout = false }
                    }
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("SPARSEBOX")
                    .font(.system(size: 27, weight: .black, design: .monospaced))
                    .tracking(-0.8)
                Text("DEVICE UTILITY / LOCAL CONSOLE")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .tracking(1.5)
                    .foregroundStyle(Color(hex: SBTheme.mutedHex))
            }
            Spacer()
            Button {
                showAbout = true
            } label: {
                Image(systemName: "info")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color(hex: SBTheme.accentHex))
                    .frame(width: 38, height: 38)
                    .background(Color(hex: SBTheme.surfaceRaisedHex))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color(hex: SBTheme.borderHex), lineWidth: 1))
            }
            .accessibilityLabel("About SparseBox")
        }
        .padding(.top, 5)
    }
}
