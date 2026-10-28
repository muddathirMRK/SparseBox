import SwiftUI
import UniformTypeIdentifiers

struct RestoreView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SBSectionTitle(title: "Restore", subtitle: "Choose a workflow to inspect compatibility and queue a payload")

                SBStatusBanner(
                    title: "Restore engine not configured",
                    message: "This project includes the restore UI and payload validation shell. It does not execute SparseRestore or BookRestore; a compatible backend must be integrated and tested for the exact device and OS build.",
                    tone: .warning
                )

                VStack(spacing: 10) {
                    NavigationLink(destination: RestoreMethodView(method: .sparseRestore)) {
                        restoreMethodCard(.sparseRestore)
                    }
                    .buttonStyle(.plain)
                    NavigationLink(destination: RestoreMethodView(method: .bookRestore)) {
                        restoreMethodCard(.bookRestore)
                    }
                    .buttonStyle(.plain)
                }

                SBCard {
                    SBSectionTitle(title: "Before you restore")
                    checklistRow("Create a current device backup", symbol: "externaldrive")
                    checklistRow("Confirm the exact iOS build and hardware", symbol: "iphone.gen3")
                    checklistRow("Keep a recovery path available", symbol: "arrow.uturn.backward.circle")
                    checklistRow("Never apply a tweak catalog blindly", symbol: "exclamationmark.triangle")
                }

                Text("Known upstream ranges are reference notes, not compatibility guarantees for this build. Exploit support can change between minor iOS releases.")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: SBTheme.mutedHex))
            }
            .padding(16)
        }
        .background(Color(hex: SBTheme.backgroundHex).ignoresSafeArea())
        .navigationTitle("Restore")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func restoreMethodCard(_ method: RestoreMethod) -> some View {
        SBCard {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: method.symbol)
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(Color(hex: SBTheme.accentHex))
                    .frame(width: 43, height: 43)
                    .background(Color(hex: SBTheme.accentHex).opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                VStack(alignment: .leading, spacing: 5) {
                    Text(method.rawValue)
                        .font(.system(size: 17, weight: .bold, design: .monospaced))
                    Text(method.detail)
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: SBTheme.mutedHex))
                    Text(method.documentedRange)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color(hex: SBTheme.warningHex))
                        .padding(.top, 2)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .foregroundStyle(Color(hex: SBTheme.mutedHex))
                    .font(.system(size: 12, weight: .bold))
            }
        }
    }

    private func checklistRow(_ text: String, symbol: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: SBTheme.accentHex))
                .frame(width: 20)
            Text(text)
                .font(.system(size: 13))
            Spacer()
        }
    }
}

struct RestoreMethodView: View {
    let method: RestoreMethod
    @State private var isImporterPresented = false
    @State private var payload: RestorePayload?
    @State private var status: ToolStatus?
    @State private var isChecking = false

    private var iOSVersion: String { UIDevice.current.systemVersion }

    private var inKnownRange: Bool {
        switch method {
        case .sparseRestore:
            return OSVersionCheck.isInRange(iOSVersion, lower: "17.0", upper: "18.1.1")
        case .bookRestore:
            return OSVersionCheck.isInRange(iOSVersion, lower: "18.2", upper: "26.1")
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SBCard {
                    HStack {
                        Image(systemName: method.symbol)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(Color(hex: SBTheme.accentHex))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(method.rawValue)
                                .font(.system(size: 21, weight: .bold, design: .monospaced))
                            Text("Current OS: iOS \(iOSVersion)")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(Color(hex: SBTheme.mutedHex))
                        }
                        Spacer()
                    }
                    Divider().overlay(Color(hex: SBTheme.borderHex))
                    HStack(spacing: 8) {
                        Image(systemName: inKnownRange ? "questionmark.circle" : "exclamationmark.triangle")
                        Text(inKnownRange ? "In the documented upstream range" : "Outside the documented upstream range")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(Color(hex: inKnownRange ? SBTheme.accentHex : SBTheme.warningHex))
                    Text(method.documentedRange)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color(hex: SBTheme.mutedHex))
                }

                SBStatusBanner(
                    title: "No restore driver loaded",
                    message: "The status above checks only the published version range. It does not prove exploit availability, payload safety, device compatibility, or successful restore execution.",
                    tone: .warning
                )

                SBSectionTitle(title: "Payload", subtitle: "Import a file for local inspection; it will not be applied")
                SBCard {
                    if let payload {
                        HStack(spacing: 11) {
                            Image(systemName: "doc.zipper")
                                .font(.system(size: 20))
                                .foregroundStyle(Color(hex: SBTheme.accentHex))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(payload.fileName)
                                    .font(.system(size: 14, weight: .semibold))
                                    .lineLimit(2)
                                Text("\(payload.size.byteCountLabel) · copied into app storage")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(Color(hex: SBTheme.mutedHex))
                            }
                            Spacer()
                            Button {
                                self.payload = nil
                                status = ToolStatus(tone: .info, title: "Payload cleared", message: "The imported file remains in SparseBox's local RestoreQueue folder until removed from Files.")
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(Color(hex: SBTheme.mutedHex))
                            }
                            .accessibilityLabel("Clear selected payload")
                        }
                    } else {
                        SBEmptyState(symbol: "doc.badge.plus", title: "No payload selected", message: "Import a file to check that it can be read and stored locally.")
                    }
                    Button {
                        isImporterPresented = true
                    } label: {
                        Label("Import payload", systemImage: "folder.badge.plus")
                    }
                    .buttonStyle(SBPrimaryButtonStyle())
                }

                Button {
                    checkReadiness()
                } label: {
                    HStack(spacing: 9) {
                        if isChecking { ProgressView().tint(Color(hex: SBTheme.backgroundHex)) }
                        Text("Check readiness")
                    }
                }
                .buttonStyle(SBSecondaryButtonStyle())
                .disabled(isChecking)

                if let status {
                    SBStatusBanner(title: status.title, message: status.message, tone: status.tone)
                }

                Text("Restore operations can change system state or make a device unbootable. The UI deliberately stops before a write or restore call until a tested backend exists.")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: SBTheme.mutedHex))
            }
            .padding(16)
        }
        .background(Color(hex: SBTheme.backgroundHex).ignoresSafeArea())
        .navigationTitle(method.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(isPresented: $isImporterPresented, allowedContentTypes: [.data, .zip, .json], allowsMultipleSelection: false) { result in
            importPayload(result)
        }
    }

    private func importPayload(_ result: Result<[URL], Error>) {
        switch result {
        case .failure(let error):
            status = ToolStatus(tone: .danger, title: "Import failed", message: error.localizedDescription)
        case .success(let urls):
            guard let url = urls.first else { return }
            let didAccess = url.startAccessingSecurityScopedResource()
            defer { if didAccess { url.stopAccessingSecurityScopedResource() } }
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                let size = (attributes[.size] as? NSNumber)?.int64Value ?? 0
                guard size > 0 else {
                    status = ToolStatus(tone: .danger, title: "Empty payload", message: "The selected file is empty. Choose a non-empty payload.")
                    return
                }
                let destination = try LocalFileService.importDirectory(url)
                payload = RestorePayload(url: destination, size: size)
                status = ToolStatus(tone: .success, title: "Payload imported", message: "The file is readable and stored locally. No restore operation has been run.")
            } catch {
                status = ToolStatus(tone: .danger, title: "Import failed", message: error.localizedDescription)
            }
        }
    }

    private func checkReadiness() {
        isChecking = true
        defer { isChecking = false }
        if payload == nil {
            status = ToolStatus(tone: .warning, title: "Payload required", message: "Import a restore payload before checking local readiness.")
        } else if !inKnownRange {
            status = ToolStatus(tone: .danger, title: "Version range mismatch", message: "This OS version is outside the published range noted for \(method.rawValue). This is informational, not a live exploit check.")
        } else {
            status = ToolStatus(tone: .warning, title: "Blocked: backend missing", message: "The payload is available locally and the OS is inside the noted range, but no restore backend is linked. Nothing was applied.")
        }
    }
}
