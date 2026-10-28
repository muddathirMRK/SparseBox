import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct DeviceToolsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SBSectionTitle(title: "Device tools", subtitle: "Local tools and import points for a paired-device bridge")
                SBStatusBanner(
                    title: "Connected-device bridge: unavailable",
                    message: "A normal iOS app cannot speak unrestricted AFC or enumerate every app and process through public APIs. This build offers local folder browsing and JSON import paths so a future bridge can plug in cleanly.",
                    tone: .warning
                )
                VStack(spacing: 0) {
                    NavigationLink(destination: AFCBrowserView()) {
                        SBToolRow(title: "AFC file browser", subtitle: "Browse a selected folder from the Files app", symbol: "folder")
                    }
                    .buttonStyle(.plain)
                    Divider().overlay(Color(hex: SBTheme.borderHex))
                    NavigationLink(destination: InstalledAppsView()) {
                        SBToolRow(title: "Installed apps", subtitle: "Inspect an imported app inventory", symbol: "square.grid.3x3")
                    }
                    .buttonStyle(.plain)
                    Divider().overlay(Color(hex: SBTheme.borderHex))
                    NavigationLink(destination: RunningProcessesView()) {
                        SBToolRow(title: "Running processes", subtitle: "Show this app's PID or import a process snapshot", symbol: "waveform.path")
                    }
                    .buttonStyle(.plain)
                    Divider().overlay(Color(hex: SBTheme.borderHex))
                    NavigationLink(destination: ProvisioningProfilesView()) {
                        SBToolRow(title: "Provisioning profiles", subtitle: "Import a .mobileprovision file and inspect metadata", symbol: "person.text.rectangle")
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
            }
            .padding(16)
        }
        .background(Color(hex: SBTheme.backgroundHex).ignoresSafeArea())
        .navigationTitle("Device")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - AFC/local folder browser

struct AFCBrowserView: View {
    @State private var showFolderImporter = false
    @State private var selectedRootURL: URL?
    @State private var currentDirectoryURL: URL?
    @State private var navigationStack: [URL] = []
    @State private var entries: [FileEntry] = []
    @State private var activeScope = false
    @State private var status: ToolStatus?
    @State private var selectedFile: FileEntry?
    @State private var searchText = ""

    private var filteredEntries: [FileEntry] {
        guard !searchText.trimmed.isEmpty else { return entries }
        return entries.filter { $0.name.localizedCaseInsensitiveContains(searchText.trimmed) }
    }

    var body: some View {
        VStack(spacing: 0) {
            if let currentDirectoryURL {
                HStack(spacing: 9) {
                    Button {
                        navigateUp()
                    } label: {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color(hex: SBTheme.accentHex))
                            .frame(width: 32, height: 32)
                            .background(Color(hex: SBTheme.surfaceRaisedHex))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .disabled(navigationStack.isEmpty)
                    .opacity(navigationStack.isEmpty ? 0.35 : 1)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(currentDirectoryURL.lastPathComponent.isEmpty ? "Selected folder" : currentDirectoryURL.lastPathComponent)
                            .font(.system(size: 13, weight: .semibold))
                            .lineLimit(1)
                        Text("\(entries.count) items · local folder")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(Color(hex: SBTheme.mutedHex))
                    }
                    Spacer()
                    Button {
                        reload()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(Color(hex: SBTheme.accentHex))
                    }
                    .accessibilityLabel("Reload folder")
                }
                .padding(12)
                .background(Color(hex: SBTheme.surfaceHex))
            }

            if selectedRootURL == nil {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        SBStatusBanner(
                            title: "AFC bridge not attached",
                            message: "Open a folder from the Files app to use the browser UI. This is a local folder browser, not a raw AFC connection to another device.",
                            tone: .warning
                        )
                        SBCard {
                            SBEmptyState(symbol: "folder.badge.questionmark", title: "No folder selected", message: "Choose a folder to inspect its contents, navigate subfolders and review file sizes.")
                            Button {
                                showFolderImporter = true
                            } label: {
                                Label("Open folder…", systemImage: "folder.badge.plus")
                            }
                            .buttonStyle(SBPrimaryButtonStyle())
                        }
                    }
                    .padding(16)
                }
            } else {
                List {
                    if let status {
                        Section {
                            Text(status.message)
                                .font(.system(size: 12))
                                .foregroundStyle(Color(hex: status.tone.titleColorHex))
                        }
                    }
                    ForEach(filteredEntries) { entry in
                        Button {
                            if entry.isDirectory {
                                enterDirectory(entry.url)
                            } else {
                                selectedFile = entry
                            }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: entry.isDirectory ? "folder.fill" : fileSymbol(entry.name))
                                    .font(.system(size: 17))
                                    .foregroundStyle(Color(hex: entry.isDirectory ? SBTheme.accentHex : SBTheme.mutedHex))
                                    .frame(width: 26)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(entry.name)
                                        .font(.system(size: 13, weight: .medium))
                                        .lineLimit(1)
                                        .foregroundStyle(.primary)
                                    Text(entry.isDirectory ? "Folder" : entry.size.byteCountLabel)
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundStyle(Color(hex: SBTheme.mutedHex))
                                }
                                Spacer()
                                Image(systemName: entry.isDirectory ? "chevron.right" : "info.circle")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(Color(hex: SBTheme.mutedHex))
                            }
                            .padding(.vertical, 2)
                        }
                        .listRowBackground(Color(hex: SBTheme.surfaceHex))
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color(hex: SBTheme.backgroundHex))
                .searchable(text: $searchText, prompt: "Filter files")
                .overlay {
                    if entries.isEmpty && status == nil {
                        SBEmptyState(symbol: "folder", title: "Empty folder", message: "This folder contains no visible items.")
                    }
                }
            }
        }
        .background(Color(hex: SBTheme.backgroundHex).ignoresSafeArea())
        .navigationTitle("AFC Browser")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showFolderImporter = true
                } label: {
                    Image(systemName: "folder.badge.plus")
                }
                .accessibilityLabel("Choose folder")
            }
        }
        .fileImporter(isPresented: $showFolderImporter, allowedContentTypes: [.folder], allowsMultipleSelection: false) { result in
            chooseFolder(result)
        }
        .sheet(item: $selectedFile) { entry in
            FileEntryDetailView(entry: entry)
        }
        .onDisappear {
            if activeScope, let selectedRootURL {
                selectedRootURL.stopAccessingSecurityScopedResource()
                activeScope = false
            }
        }
    }

    private func chooseFolder(_ result: Result<[URL], Error>) {
        switch result {
        case .failure(let error):
            status = ToolStatus(tone: .danger, title: "Folder selection failed", message: error.localizedDescription)
        case .success(let urls):
            guard let url = urls.first else { return }
            if activeScope, let selectedRootURL {
                selectedRootURL.stopAccessingSecurityScopedResource()
            }
            let accessed = url.startAccessingSecurityScopedResource()
            selectedRootURL = url
            currentDirectoryURL = url
            navigationStack = []
            activeScope = accessed
            status = nil
            reload()
        }
    }

    private func reload() {
        guard let currentDirectoryURL else { return }
        do {
            entries = try LocalFileService.listDirectory(currentDirectoryURL)
            status = nil
        } catch {
            entries = []
            status = ToolStatus(tone: .danger, title: "Directory read failed", message: error.localizedDescription)
        }
    }

    private func enterDirectory(_ url: URL) {
        guard let currentDirectoryURL else { return }
        navigationStack.append(currentDirectoryURL)
        currentDirectoryURLSetter(url)
        reload()
    }

    private func currentDirectoryURLSetter(_ url: URL) {
        currentDirectoryURL = url
    }

    private func navigateUp() {
        guard let previous = navigationStack.popLast() else { return }
        currentDirectoryURLSetter(previous)
        reload()
    }

    private func fileSymbol(_ name: String) -> String {
        let ext = URL(fileURLWithPath: name).pathExtension.lowercased()
        switch ext {
        case "json", "plist": return "curlybraces"
        case "png", "jpg", "jpeg", "heic": return "photo"
        case "zip", "ipa", "gz": return "doc.zipper"
        case "txt", "log", "md": return "doc.text"
        case "mobileprovision": return "person.text.rectangle"
        default: return "doc"
        }
    }
}

struct FileEntryDetailView: View {
    let entry: FileEntry
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    SBCard {
                        Label(entry.name, systemImage: "doc.text")
                            .font(.system(size: 17, weight: .bold))
                        metadataRow("Type", value: entry.url.pathExtension.isEmpty ? "No extension" : entry.url.pathExtension.uppercased())
                        metadataRow("Size", value: entry.size.byteCountLabel)
                        metadataRow("Modified", value: entry.modified?.mediumDateTimeLabel ?? "Unknown")
                        metadataRow("Path", value: entry.url.path)
                    }
                    SBStatusBanner(title: "Read-only inspection", message: "This screen displays local file metadata. It does not edit system files or transmit contents.", tone: .info)
                }
                .padding(16)
            }
            .background(Color(hex: SBTheme.backgroundHex).ignoresSafeArea())
            .navigationTitle("File details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func metadataRow(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(Color(hex: SBTheme.mutedHex))
            Text(value)
                .font(.system(size: 12, design: .monospaced))
                .textSelection(.enabled)
        }
    }
}

// MARK: - Installed apps inventory

struct InstalledAppsView: View {
    @State private var apps: [AppRecord] = []
    @State private var showImporter = false
    @State private var status: ToolStatus?
    @State private var searchText = ""

    private var filteredApps: [AppRecord] {
        guard !searchText.trimmed.isEmpty else { return apps }
        return apps.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.bundleID.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SBStatusBanner(
                    title: "Requires inventory import",
                    message: "iOS does not provide a public API for a normal app to list every installed app. Import a JSON snapshot created by a paired-device helper.",
                    tone: .warning
                )
                Button {
                    showImporter = true
                } label: {
                    Label("Import app inventory JSON", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(SBPrimaryButtonStyle())

                if let status {
                    SBStatusBanner(title: status.title, message: status.message, tone: status.tone)
                }

                if apps.isEmpty {
                    SBCard {
                        SBEmptyState(symbol: "square.grid.3x3", title: "No inventory loaded", message: "JSON may be an array of { name, bundleID, version } entries or an object containing an apps array.")
                    }
                } else {
                    SBSectionTitle(title: "Apps", subtitle: "\(apps.count) imported records")
                    ForEach(filteredApps) { app in
                        SBCard(padding: 12) {
                            HStack(spacing: 11) {
                                Image(systemName: "app.dashed")
                                    .font(.system(size: 19))
                                    .foregroundStyle(Color(hex: SBTheme.accentHex))
                                    .frame(width: 36, height: 36)
                                    .background(Color(hex: SBTheme.accentHex).opacity(0.10))
                                    .clipShape(RoundedRectangle(cornerRadius: 9))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(app.name).font(.system(size: 14, weight: .semibold))
                                    Text(app.bundleID)
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundStyle(Color(hex: SBTheme.mutedHex))
                                        .textSelection(.enabled)
                                    if let version = app.version {
                                        Text("Version \(version)")
                                            .font(.system(size: 11))
                                            .foregroundStyle(Color(hex: SBTheme.mutedHex))
                                    }
                                }
                                Spacer(minLength: 0)
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Color(hex: SBTheme.backgroundHex).ignoresSafeArea())
        .navigationTitle("Installed Apps")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Filter inventory")
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json], allowsMultipleSelection: false) { result in
            importApps(result)
        }
    }

    private func importApps(_ result: Result<[URL], Error>) {
        switch result {
        case .failure(let error):
            status = ToolStatus(tone: .danger, title: "Import failed", message: error.localizedDescription)
        case .success(let urls):
            guard let url = urls.first else { return }
            let accessed = url.startAccessingSecurityScopedResource()
            defer { if accessed { url.stopAccessingSecurityScopedResource() } }
            do {
                let data = try Data(contentsOf: url)
                let envelope = try JSONDecoder().decode(InventoryEnvelope<AppRecord>.self, from: data)
                guard !envelope.items.isEmpty else {
                    status = ToolStatus(tone: .warning, title: "No records found", message: "The JSON did not contain an app array. See the expected schema in the empty-state message.")
                    return
                }
                apps = envelope.items.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                status = ToolStatus(tone: .success, title: "Inventory loaded", message: "Loaded \(apps.count) app records from \(url.lastPathComponent).")
            } catch {
                status = ToolStatus(tone: .danger, title: "Could not parse JSON", message: error.localizedDescription)
            }
        }
    }
}

// MARK: - Running processes

struct RunningProcessesView: View {
    @State private var importedProcesses: [ProcessRecord] = []
    @State private var showImporter = false
    @State private var status: ToolStatus?
    @State private var searchText = ""
    private let local = LocalDeviceSummary.current

    private var visibleProcesses: [ProcessRecord] {
        let items = importedProcesses
        guard !searchText.trimmed.isEmpty else { return items }
        return items.filter { $0.name.localizedCaseInsensitiveContains(searchText) || String($0.pid).contains(searchText) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SBCard {
                    SBSectionTitle(title: "This process")
                    HStack(spacing: 12) {
                        Image(systemName: "waveform.path")
                            .font(.system(size: 20))
                            .foregroundStyle(Color(hex: SBTheme.accentHex))
                            .frame(width: 42, height: 42)
                            .background(Color(hex: SBTheme.accentHex).opacity(0.10))
                            .clipShape(RoundedRectangle(cornerRadius: 11))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("SparseBox")
                                .font(.system(size: 15, weight: .bold))
                            Text("PID \(local.processID) · current app only")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(Color(hex: SBTheme.mutedHex))
                        }
                        Spacer()
                        Text("LIVE")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color(hex: SBTheme.accentHex))
                    }
                }

                SBStatusBanner(
                    title: "System process list not available",
                    message: "Stock iOS restricts system-wide process inspection and does not let an ordinary app terminate other processes. Import a paired-device process snapshot to inspect it here.",
                    tone: .warning
                )
                Button {
                    showImporter = true
                } label: {
                    Label("Import process snapshot JSON", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(SBPrimaryButtonStyle())

                if let status {
                    SBStatusBanner(title: status.title, message: status.message, tone: status.tone)
                }

                if importedProcesses.isEmpty {
                    SBCard {
                        SBEmptyState(symbol: "waveform.path", title: "No external snapshot", message: "Expected JSON: an array of { pid, name, user?, state? } entries or an object containing a processes array.")
                    }
                } else {
                    SBSectionTitle(title: "Imported processes", subtitle: "\(importedProcesses.count) records")
                    ForEach(visibleProcesses) { process in
                        SBCard(padding: 12) {
                            HStack(spacing: 10) {
                                Text(String(process.pid))
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundStyle(Color(hex: SBTheme.accentHex))
                                    .frame(width: 58, alignment: .leading)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(process.name).font(.system(size: 14, weight: .semibold))
                                    Text([process.user, process.state].compactMap { $0 }.joined(separator: " · "))
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundStyle(Color(hex: SBTheme.mutedHex))
                                }
                                Spacer(minLength: 0)
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Color(hex: SBTheme.backgroundHex).ignoresSafeArea())
        .navigationTitle("Processes")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Filter snapshot")
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json], allowsMultipleSelection: false) { result in
            importProcesses(result)
        }
    }

    private func importProcesses(_ result: Result<[URL], Error>) {
        switch result {
        case .failure(let error):
            status = ToolStatus(tone: .danger, title: "Import failed", message: error.localizedDescription)
        case .success(let urls):
            guard let url = urls.first else { return }
            let accessed = url.startAccessingSecurityScopedResource()
            defer { if accessed { url.stopAccessingSecurityScopedResource() } }
            do {
                let data = try Data(contentsOf: url)
                let envelope = try JSONDecoder().decode(InventoryEnvelope<ProcessRecord>.self, from: data)
                guard !envelope.items.isEmpty else {
                    status = ToolStatus(tone: .warning, title: "No records found", message: "The file parsed, but it did not contain process records.")
                    return
                }
                importedProcesses = envelope.items.sorted { $0.pid < $1.pid }
                status = ToolStatus(tone: .success, title: "Snapshot loaded", message: "Loaded \(importedProcesses.count) process records.")
            } catch {
                status = ToolStatus(tone: .danger, title: "Could not parse JSON", message: error.localizedDescription)
            }
        }
    }
}

// MARK: - Provisioning profiles

struct ProvisioningProfilesView: View {
    @State private var profiles: [ProfileRecord] = []
    @State private var showImporter = false
    @State private var status: ToolStatus?
    @State private var selectedProfile: ProfileRecord?

    private var profileType: UTType { UTType(filenameExtension: "mobileprovision") ?? .data }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SBStatusBanner(
                    title: "Local profile inspector",
                    message: "Import a .mobileprovision file to extract its embedded plist metadata where readable. Importing does not install the profile or enumerate profiles installed by iOS.",
                    tone: .info
                )
                Button {
                    showImporter = true
                } label: {
                    Label("Import provisioning profile", systemImage: "person.text.rectangle")
                }
                .buttonStyle(SBPrimaryButtonStyle())

                if let status {
                    SBStatusBanner(title: status.title, message: status.message, tone: status.tone)
                }

                if profiles.isEmpty {
                    SBCard {
                        SBEmptyState(symbol: "person.text.rectangle", title: "No profiles imported", message: "Choose a provisioning profile from Files. Imported copies are stored in SparseBox/Profiles in the app's Documents folder.")
                    }
                } else {
                    SBSectionTitle(title: "Imported profiles", subtitle: "\(profiles.count) files")
                    ForEach(profiles) { profile in
                        Button {
                            selectedProfile = profile
                        } label: {
                            SBCard(padding: 13) {
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: profile.isExpired ? "xmark.shield" : "checkmark.shield")
                                        .font(.system(size: 20))
                                        .foregroundStyle(Color(hex: profile.isExpired ? SBTheme.dangerHex : SBTheme.accentHex))
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(profile.profileName ?? profile.fileName)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(.primary)
                                        Text(profile.teamName ?? "Team name unavailable")
                                            .font(.system(size: 11))
                                            .foregroundStyle(Color(hex: SBTheme.mutedHex))
                                        Text(profile.expirationDate.map { "Expires \($0.mediumDateTimeLabel)" } ?? "Expiration not parsed")
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundStyle(Color(hex: profile.isExpired ? SBTheme.dangerHex : SBTheme.mutedHex))
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(Color(hex: SBTheme.mutedHex))
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
        }
        .background(Color(hex: SBTheme.backgroundHex).ignoresSafeArea())
        .navigationTitle("Profiles")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [profileType, .data], allowsMultipleSelection: false) { result in
            importProfile(result)
        }
        .sheet(item: $selectedProfile) { profile in
            ProfileDetailView(profile: profile)
        }
    }

    private func importProfile(_ result: Result<[URL], Error>) {
        switch result {
        case .failure(let error):
            status = ToolStatus(tone: .danger, title: "Import failed", message: error.localizedDescription)
        case .success(let urls):
            guard let source = urls.first else { return }
            let accessed = source.startAccessingSecurityScopedResource()
            defer { if accessed { source.stopAccessingSecurityScopedResource() } }
            do {
                let data = try Data(contentsOf: source)
                let destination = try LocalFileService.persistProfile(sourceURL: source, data: data)
                let metadata = LocalFileService.profileMetadata(from: data)
                let attributes = try FileManager.default.attributesOfItem(atPath: destination.path)
                let size = (attributes[.size] as? NSNumber)?.int64Value ?? Int64(data.count)
                let profile = ProfileRecord(
                    fileName: destination.lastPathComponent,
                    fileURL: destination,
                    size: size,
                    profileName: metadata.name,
                    profileUUID: metadata.uuid,
                    teamName: metadata.teamName,
                    expirationDate: metadata.expiry
                )
                profiles.insert(profile, at: 0)
                status = ToolStatus(tone: .success, title: "Profile imported", message: metadata.uuid == nil ? "Copied the file, but the embedded plist metadata could not be extracted." : "Copied the file and extracted its profile metadata.")
            } catch {
                status = ToolStatus(tone: .danger, title: "Import failed", message: error.localizedDescription)
            }
        }
    }
}

struct ProfileDetailView: View {
    let profile: ProfileRecord
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    SBCard {
                        metadataRow("Profile name", value: profile.profileName ?? "Not parsed")
                        metadataRow("UUID", value: profile.profileUUID ?? "Not parsed")
                        metadataRow("Team", value: profile.teamName ?? "Not parsed")
                        metadataRow("File", value: profile.fileName)
                        metadataRow("Size", value: profile.size.byteCountLabel)
                        metadataRow("Expires", value: profile.expirationDate?.mediumDateTimeLabel ?? "Not parsed")
                        metadataRow("Local path", value: profile.fileURL.path)
                    }
                    SBStatusBanner(title: "Metadata only", message: "The profile's CMS signature is not validated here. This page does not install or trust the profile.", tone: .warning)
                }
                .padding(16)
            }
            .background(Color(hex: SBTheme.backgroundHex).ignoresSafeArea())
            .navigationTitle("Profile details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func metadataRow(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(Color(hex: SBTheme.mutedHex))
            Text(value)
                .font(.system(size: 12, design: .monospaced))
                .textSelection(.enabled)
        }
    }
}
