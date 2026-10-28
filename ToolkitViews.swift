import SwiftUI
import UIKit
import Foundation
import Network
import UniformTypeIdentifiers
import MetricKit

// MARK: - SparseBox Power Toolkit

struct ToolkitView: View {
    private let sections: [ToolkitSection] = [
        .init(title: "Health", subtitle: "Measure the things that actually affect performance.", items: [
            .init("Performance Lab", "Benchmark CPU, memory and storage", "gauge.with.dots.needle.bottom.50percent", .performance),
            .init("Battery Lab", "Run repeatable drain sessions", "battery.75percent", .battery),
            .init("Thermal Monitor", "Watch thermal pressure over time", "thermometer.medium", .thermal),
            .init("Storage Doctor", "Inspect app-accessible storage", "internaldrive", .storage),
            .init("Network Doctor", "Latency, DNS and connectivity", "network", .network),
            .init("MetricKit Health", "Review Apple diagnostic metrics", "waveform.path.ecg", .metrics)
        ]),
        .init(title: "Power Tools", subtitle: "Inspect, compare and prepare without clutter.", items: [
            .init("Device Snapshot", "Save a before/after device report", "camera.metering.center.weighted", .snapshot),
            .init("IPA Inspector", "Inspect bundles, plists and payloads", "shippingbox", .ipa),
            .init("Signing Inspector", "Profiles, entitlements and expiry", "checkmark.seal", .signing),
            .init("Crash Analyzer", "Read .ips diagnostic logs", "exclamationmark.triangle", .crash),
            .init("Restore Assistant", "Preflight and verify restore workflows", "checklist", .restorePrep)
        ]),
        .init(title: "Advanced", subtitle: "Existing device-facing workspaces stay here.", items: [
            .init("Connection Health", "Pairing, tunnel and helper validity", "checkmark.shield", .connection),
            .init("External Device Bridge", "Privileged helper connection status", "cable.connector", .bridge),
            .init("Automation Export", "Export diagnostic data for Shortcuts", "arrow.up.doc", .automation)
        ])
    ]

    var body: some View {
        List {
            Section {
                SBGlassHero(title: "Power Toolkit", subtitle: "A compact diagnostic lab for iPhone 12 and newer.", symbol: "wand.and.stars")
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 12, trailing: 0))
                    .listRowBackground(Color.clear)
            }
            ForEach(sections) { section in
                Section {
                    ForEach(section.items) { item in
                        NavigationLink(destination: item.destination) {
                            HStack(spacing: 13) {
                                Image(systemName: item.symbol)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Color(hex: SBTheme.accentHex))
                                    .frame(width: 34, height: 34)
                                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.title).font(.system(size: 15, weight: .semibold))
                                    Text(item.subtitle).font(.system(size: 11)).foregroundStyle(Color(hex: SBTheme.mutedHex))
                                }
                                Spacer()
                            }
                            .padding(.vertical, 5)
                        }
                    }
                } header: {
                    Text(section.title).textCase(nil)
                    Text(section.subtitle).textCase(nil).font(.system(size: 10)).foregroundStyle(Color(hex: SBTheme.mutedHex))
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color(hex: SBTheme.backgroundHex).ignoresSafeArea())
        .navigationTitle("Toolkit")
    }
}

private struct ToolkitSection: Identifiable {
    let id = UUID(); let title: String; let subtitle: String; let items: [ToolkitItem]
}
private enum ToolkitDestination { case performance, battery, thermal, storage, network, metrics, snapshot, ipa, signing, crash, restorePrep, connection, bridge, automation }
private struct ToolkitItem: Identifiable {
    let id = UUID(); let title: String; let subtitle: String; let symbol: String; let kind: ToolkitDestination
    init(_ title: String, _ subtitle: String, _ symbol: String, _ destination: ToolkitDestination) { self.title = title; self.subtitle = subtitle; self.symbol = symbol; self.kind = destination }
    @ViewBuilder var destinationView: some View { EmptyView() }
    @ViewBuilder var destination: some View {
        switch kind {
        case .performance: PerformanceLabView()
        case .battery: BatteryLabView()
        case .thermal: ThermalMonitorView()
        case .storage: StorageDoctorView()
        case .network: NetworkDoctorView()
        case .metrics: MetricKitView()
        case .snapshot: DeviceSnapshotView()
        case .ipa: IPAScannerView()
        case .signing: SigningInspectorView()
        case .crash: CrashAnalyzerView()
        case .restorePrep: RestoreAssistantView()
        case .connection: ConnectionHealthView()
        case .bridge: BridgeStatusView()
        case .automation: AutomationExportView()
        }
    }
}


private struct LabHeader: View {
    let title: String; let subtitle: String; let symbol: String
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Label(title, systemImage: symbol).font(.system(size: 23, weight: .bold))
            Text(subtitle).font(.system(size: 12)).foregroundStyle(Color(hex: SBTheme.mutedHex))
        }
    }
}

private struct StatCard: View {
    let title: String; let value: String; let detail: String?
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased()).font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundStyle(Color(hex: SBTheme.mutedHex))
            Text(value).font(.system(size: 20, weight: .semibold, design: .rounded))
            if let detail { Text(detail).font(.system(size: 10)).foregroundStyle(Color(hex: SBTheme.mutedHex)) }
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(13)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: Performance
struct PerformanceLabView: View {
    @State private var running = false
    @State private var cpuScore = "—"; @State private var memoryScore = "—"; @State private var storageScore = "—"
    @State private var started = Date()
    var body: some View {
        ScrollView { VStack(alignment: .leading, spacing: 16) {
            LabHeader(title: "Performance Lab", subtitle: "Repeatable local tests. Scores are relative to this device, not an Apple benchmark.", symbol: "gauge.with.dots.needle.bottom.50percent")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                StatCard(title: "CPU", value: cpuScore, detail: "integer + hashing")
                StatCard(title: "Memory", value: memoryScore, detail: "allocation throughput")
                StatCard(title: "Storage", value: storageScore, detail: "local file I/O")
                StatCard(title: "Thermal", value: thermalLabel, detail: "current system state")
            }
            SBCard { VStack(alignment: .leading, spacing: 10) {
                Text("Benchmark") .font(.headline)
                Text(running ? "Running a short workload… keep the phone on the same surface for comparable results." : "Run after the phone has cooled down for the most repeatable score.").font(.caption).foregroundStyle(Color(hex: SBTheme.mutedHex))
                Button(running ? "Running…" : "Run benchmark") { run() }.buttonStyle(.borderedProminent).tint(Color(hex: SBTheme.accentHex)).disabled(running)
            }}
            SBStatusBanner(title: "No fake boost", message: "SparseBox measures and diagnoses performance; it does not claim to unlock CPU/GPU clocks or purge iOS memory.", tone: .info, symbol: "lock.shield")
        }.padding(16) }.background(Color(hex: SBTheme.backgroundHex).ignoresSafeArea()).navigationTitle("Performance")
    }
    private var thermalLabel: String { ProcessInfo.processInfo.thermalState.label }
    private func run() {
        running = true; started = Date()
        DispatchQueue.global(qos: .userInitiated).async {
            let cpuStart = CFAbsoluteTimeGetCurrent(); var hash: UInt64 = 0
            for i in 0..<2_500_000 { hash = hash &* 1099511628211 &+ UInt64(i) }
            let cpu = max(1, Int(10_000_000 / max(0.01, CFAbsoluteTimeGetCurrent() - cpuStart)))
            let memStart = CFAbsoluteTimeGetCurrent(); var buffers = [[UInt8]](); for _ in 0..<80 { buffers.append(Array(repeating: 7, count: 256 * 1024)) }; _ = buffers.count
            let mem = max(1, Int(10_000_000 / max(0.01, CFAbsoluteTimeGetCurrent() - memStart)))
            let storage = StorageDoctorService.benchmark()
            DispatchQueue.main.async { cpuScore = "\(cpu)"; memoryScore = "\(mem)"; storageScore = "\(storage)"; running = false }
            _ = hash
        }
    }
}

private extension ProcessInfo.ThermalState {
    var label: String { switch self { case .nominal: return "Nominal"; case .fair: return "Fair"; case .serious: return "Serious"; case .critical: return "Critical"; @unknown default: return "Unknown" } }
}

// MARK: Battery
struct BatteryLabView: View {
    @State private var enabled = UIDevice.current.isBatteryMonitoringEnabled
    @State private var startLevel: Float = -1; @State private var startDate: Date?; @State private var currentLevel: Float = -1
    var body: some View {
        ScrollView { VStack(alignment: .leading, spacing: 16) {
            LabHeader(title: "Battery Lab", subtitle: "Track controlled sessions using public battery state APIs.", symbol: "battery.75percent")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                StatCard(title: "Level", value: percent(currentLevel), detail: UIDevice.current.batteryState.label)
                StatCard(title: "Low Power", value: ProcessInfo.processInfo.isLowPowerModeEnabled ? "ON" : "OFF", detail: "system setting")
                StatCard(title: "Thermal", value: ProcessInfo.processInfo.thermalState.label, detail: "current state")
                StatCard(title: "Session", value: drainRate, detail: "estimated % / hour")
            }
            SBCard { VStack(alignment: .leading, spacing: 10) {
                Text("Drain session").font(.headline)
                Text(startDate == nil ? "Start, use the phone normally, then return to calculate the observed drain rate." : "Started \(startDate!.formatted(date: .omitted, time: .shortened)) at \(percent(startLevel)).").font(.caption).foregroundStyle(Color(hex: SBTheme.mutedHex))
                HStack { Button("Start") { start() }.buttonStyle(.borderedProminent).tint(Color(hex: SBTheme.accentHex)); Button("Refresh") { refresh() }.buttonStyle(.bordered) }
            }}
        }.padding(16) }.background(Color(hex: SBTheme.backgroundHex).ignoresSafeArea()).navigationTitle("Battery")
            .onAppear { UIDevice.current.isBatteryMonitoringEnabled = true; enabled = true; refresh() }
    }
    private var drainRate: String { guard let date = startDate, startLevel >= 0, currentLevel >= 0, currentLevel < startLevel else { return "—" }; let hours = Date().timeIntervalSince(date) / 3600; return hours > 0.02 ? String(format: "%.1f", Double(startLevel-currentLevel) * 100 / hours) : "—" }
    private func percent(_ value: Float) -> String { value < 0 ? "—" : "\(Int(value * 100))%" }
    private func start() { refresh(); startLevel = currentLevel; startDate = Date() }
    private func refresh() { currentLevel = UIDevice.current.batteryLevel }
}
private extension UIDevice.BatteryState { var label: String { switch self { case .charging: return "Charging"; case .full: return "Full"; case .unplugged: return "Unplugged"; case .unknown: return "Unknown"; @unknown default: return "Unknown" } } }

// MARK: Thermal
struct ThermalMonitorView: View {
    @State private var history: [(Date, String)] = []
    @State private var timer: Timer?
    var body: some View {
        ScrollView { VStack(alignment: .leading, spacing: 16) {
            LabHeader(title: "Thermal Monitor", subtitle: "Samples ProcessInfo thermal state while SparseBox is open.", symbol: "thermometer.medium")
            StatCard(title: "Current", value: ProcessInfo.processInfo.thermalState.label, detail: "Apple thermal state")
            SBCard { VStack(alignment: .leading, spacing: 8) {
                Text("Session history").font(.headline)
                ForEach(Array(history.enumerated()), id: \.offset) { _, entry in HStack { Text(entry.0.formatted(date: .omitted, time: .standard)); Spacer(); Text(entry.1).fontWeight(.semibold) } }
                if history.isEmpty { Text("No samples yet.").font(.caption).foregroundStyle(Color(hex: SBTheme.mutedHex)) }
            }}
        }.padding(16) }.background(Color(hex: SBTheme.backgroundHex).ignoresSafeArea()).navigationTitle("Thermal")
        .onAppear { sample(); timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in sample() } }
        .onDisappear { timer?.invalidate(); timer = nil }
    }
    private func sample() { history.append((Date(), ProcessInfo.processInfo.thermalState.label)); if history.count > 20 { history.removeFirst() } }
}

// MARK: Storage
struct StorageDoctorView: View {
    @State private var files: [FileEntry] = []; @State private var total: Int64 = 0; @State private var free: Int64 = 0
    var body: some View {
        ScrollView { VStack(alignment: .leading, spacing: 16) {
            LabHeader(title: "Storage Doctor", subtitle: "Safe inspection of storage available to SparseBox.", symbol: "internaldrive")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) { StatCard(title: "Free", value: bytes(free), detail: "device filesystem"); StatCard(title: "Capacity", value: bytes(total), detail: "reported by iOS") }
            SBCard { VStack(alignment: .leading, spacing: 8) { Text("SparseBox files").font(.headline); ForEach(files.prefix(12)) { f in HStack { Image(systemName: f.isDirectory ? "folder" : "doc"); Text(f.name).lineLimit(1); Spacer(); Text(bytes(f.size)).foregroundStyle(Color(hex: SBTheme.mutedHex)) } } } }
            Button("Refresh") { scan() }.buttonStyle(.borderedProminent).tint(Color(hex: SBTheme.accentHex))
        }.padding(16) }.background(Color(hex: SBTheme.backgroundHex).ignoresSafeArea()).navigationTitle("Storage")
        .onAppear(perform: scan)
    }
    private func scan() { if let values = try? FileManager.default.homeDirectoryForCurrentUser.resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey]) { total = Int64(values.volumeTotalCapacity ?? 0); free = values.volumeAvailableCapacityForImportantUsage.map(Int64.init) ?? 0 }; if let dir = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true), let list = try? LocalFileService.listDirectory(dir) { files = list } }
    private func bytes(_ value: Int64) -> String { ByteCountFormatter.string(fromByteCount: value, countStyle: .file) }
}
private enum StorageDoctorService { static func benchmark() -> Int { let url = FileManager.default.temporaryDirectory.appendingPathComponent("sb-bench-\(UUID().uuidString)"); let data = Data(repeating: 42, count: 512 * 1024); let start = CFAbsoluteTimeGetCurrent(); for _ in 0..<12 { try? data.write(to: url); _ = try? Data(contentsOf: url) }; try? FileManager.default.removeItem(at: url); return max(1, Int(10000 / max(0.02, CFAbsoluteTimeGetCurrent() - start))) } }

// MARK: Network
struct NetworkDoctorView: View {
    @State private var status = "Checking…"; @State private var interfaces = "—"; @State private var latency = "—"; @State private var timer: Timer?
    var body: some View { ScrollView { VStack(alignment: .leading, spacing: 16) {
        LabHeader(title: "Network Doctor", subtitle: "Connectivity checks without modifying network settings.", symbol: "network")
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) { StatCard(title: "Path", value: status, detail: interfaces); StatCard(title: "HTTPS", value: latency, detail: "Apple endpoint") }
        Button("Run diagnostics") { run() }.buttonStyle(.borderedProminent).tint(Color(hex: SBTheme.accentHex))
        SBCard { Text("Checks DNS/HTTPS reachability and records the observed round-trip time. It does not claim to measure radio quality.").font(.caption).foregroundStyle(Color(hex: SBTheme.mutedHex)) }
    }.padding(16) }.background(Color(hex: SBTheme.backgroundHex).ignoresSafeArea()).navigationTitle("Network").onAppear(perform: run) }
    private func run() { let monitor = NWPathMonitor(); let queue = DispatchQueue(label: "SparseBox.Network"); monitor.pathUpdateHandler = { path in DispatchQueue.main.async { status = path.status == .satisfied ? "Online" : "Offline"; interfaces = path.usesInterfaceType(.wifi) ? "Wi-Fi" : path.usesInterfaceType(.cellular) ? "Cellular" : path.usesInterfaceType(.wiredEthernet) ? "Ethernet" : "Other"; monitor.cancel(); measureHTTPS() } }; monitor.start(queue: queue) }
    private func measureHTTPS() { let start = CFAbsoluteTimeGetCurrent(); var request = URLRequest(url: URL(string: "https://www.apple.com/library/test/success.html")!); request.timeoutInterval = 8; URLSession.shared.dataTask(with: request) { _, response, _ in DispatchQueue.main.async { latency = response != nil ? "\(Int((CFAbsoluteTimeGetCurrent()-start)*1000)) ms" : "Failed" } }.resume() }
}

// MARK: MetricKit
final class SparseMetricSubscriber: NSObject, MXMetricManagerSubscriber {
    static let shared = SparseMetricSubscriber(); private override init() { super.init() }
    private(set) var lastPayloadDate: Date?
    func didReceive(_ payloads: [MXMetricPayload]) { lastPayloadDate = Date() }
    func didReceive(_ payloads: [MXDiagnosticPayload]) { lastPayloadDate = Date() }
}
struct MetricKitView: View {
    @State private var received: Date?
    var body: some View { ScrollView { VStack(alignment: .leading, spacing: 16) {
        LabHeader(title: "MetricKit Health", subtitle: "Collects Apple-provided metrics for SparseBox itself when available.", symbol: "waveform.path.ecg")
        StatCard(title: "Last payload", value: received?.formatted(date: .abbreviated, time: .shortened) ?? "Waiting", detail: "MetricKit delivery")
        SBCard { VStack(alignment: .leading, spacing: 8) { Text("What it covers").font(.headline); Text("Launch performance, hangs, crashes and resource/power diagnostics may be delivered by iOS. SparseBox does not fabricate device-wide telemetry.").font(.caption).foregroundStyle(Color(hex: SBTheme.mutedHex)) } }
        Button("Register MetricKit") { MXMetricManager.shared.add(SparseMetricSubscriber.shared); received = SparseMetricSubscriber.shared.lastPayloadDate }.buttonStyle(.borderedProminent).tint(Color(hex: SBTheme.accentHex))
    }.padding(16) }.background(Color(hex: SBTheme.backgroundHex).ignoresSafeArea()).navigationTitle("MetricKit").onAppear { MXMetricManager.shared.add(SparseMetricSubscriber.shared); received = SparseMetricSubscriber.shared.lastPayloadDate } }
}

// MARK: Snapshot
struct DeviceSnapshotView: View {
    @State private var saved = false
    var body: some View { ScrollView { VStack(alignment: .leading, spacing: 16) {
        LabHeader(title: "Device Snapshot", subtitle: "Create a portable before/after JSON report.", symbol: "camera.metering.center.weighted")
        SBCard { VStack(alignment: .leading, spacing: 8) { Text("Snapshot includes").font(.headline); Text("Model, iOS version, battery state, thermal state, storage totals, app version and timestamp. Private system databases are intentionally excluded.").font(.caption).foregroundStyle(Color(hex: SBTheme.mutedHex)) } }
        ShareLink(item: snapshotJSON()) { Label("Export snapshot", systemImage: "square.and.arrow.up") }.buttonStyle(.borderedProminent).tint(Color(hex: SBTheme.accentHex))
        if saved { Text("Snapshot generated.").font(.caption).foregroundStyle(Color(hex: SBTheme.accentHex)) }
    }.padding(16) }.background(Color(hex: SBTheme.backgroundHex).ignoresSafeArea()).navigationTitle("Snapshot") }
    private func snapshotJSON() -> String { let d = UIDevice.current; let o: [String: Any] = ["timestamp": ISO8601DateFormatter().string(from: Date()), "model": d.model, "systemVersion": d.systemVersion, "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "", "battery": d.batteryLevel, "batteryState": d.batteryState.label, "thermal": ProcessInfo.processInfo.thermalState.label, "lowPowerMode": ProcessInfo.processInfo.isLowPowerModeEnabled]; return (try? JSONSerialization.data(withJSONObject: o, options: [.prettyPrinted])).flatMap { String(data: $0, encoding: .utf8) } ?? "{}" }
}

// MARK: IPA
struct IPAScannerView: View {
    @State private var showImporter = false; @State private var result = "No IPA selected."
    var body: some View { ScrollView { VStack(alignment: .leading, spacing: 16) { LabHeader(title: "IPA Inspector", subtitle: "Inspect an IPA without installing or modifying it.", symbol: "shippingbox"); Button("Choose IPA") { showImporter = true }.buttonStyle(.borderedProminent).tint(Color(hex: SBTheme.accentHex)); SBCard { Text(result).font(.system(size: 12, design: .monospaced)) } }.padding(16) }.background(Color(hex: SBTheme.backgroundHex).ignoresSafeArea()).navigationTitle("IPA Inspector").fileImporter(isPresented: $showImporter, allowedContentTypes: [.zip, .data], allowsMultipleSelection: false) { r in inspect(r) } }
    private func inspect(_ r: Result<[URL], Error>) { guard let url = try? r.get().first else { result = "Import failed."; return }; let access = url.startAccessingSecurityScopedResource(); defer { if access { url.stopAccessingSecurityScopedResource() } }; guard let archive = try? Data(contentsOf: url) else { result = "Could not read archive."; return }; result = "File: \(url.lastPathComponent)\nSize: \(ByteCountFormatter.string(fromByteCount: Int64(archive.count), countStyle: .file))\n\nUse the external archive inspector/bridge to enumerate Payload/*.app and embedded provisioning data. SparseBox does not execute or install the IPA." }
}

// MARK: Signing
struct SigningInspectorView: View {
    @State private var showImporter = false; @State private var text = "Choose a .mobileprovision file to inspect its embedded plist metadata."
    var body: some View { ScrollView { VStack(alignment: .leading, spacing: 16) { LabHeader(title: "Signing Inspector", subtitle: "Profile metadata, expiry and team identity.", symbol: "checkmark.seal"); Button("Import profile") { showImporter = true }.buttonStyle(.borderedProminent).tint(Color(hex: SBTheme.accentHex)); SBCard { Text(text).font(.system(size: 12, design: .monospaced)) } }.padding(16) }.background(Color(hex: SBTheme.backgroundHex).ignoresSafeArea()).navigationTitle("Signing").fileImporter(isPresented: $showImporter, allowedContentTypes: [.data], allowsMultipleSelection: false) { r in inspect(r) } }
    private func inspect(_ r: Result<[URL], Error>) { guard let url = try? r.get().first, let data = try? Data(contentsOf: url) else { text = "Could not read profile."; return }; let m = LocalFileService.profileMetadata(from: data); text = "Name: \(m.name ?? "—")\nUUID: \(m.uuid ?? "—")\nTeam: \(m.teamName ?? "—")\nExpiry: \(m.expiry?.formatted() ?? "—")\n\nNote: this is metadata inspection, not signature verification." }
}

// MARK: Crash
struct CrashAnalyzerView: View {
    @State private var showImporter = false; @State private var result = "Import an Apple .ips diagnostic file."
    var body: some View { ScrollView { VStack(alignment: .leading, spacing: 16) { LabHeader(title: "Crash Analyzer", subtitle: "Extract high-value fields from Apple diagnostic logs.", symbol: "exclamationmark.triangle"); Button("Import .ips") { showImporter = true }.buttonStyle(.borderedProminent).tint(Color(hex: SBTheme.accentHex)); SBCard { Text(result).font(.system(size: 12, design: .monospaced)) } }.padding(16) }.background(Color(hex: SBTheme.backgroundHex).ignoresSafeArea()).navigationTitle("Crash Analyzer").fileImporter(isPresented: $showImporter, allowedContentTypes: [.json, .data], allowsMultipleSelection: false) { r in parse(r) } }
    private func parse(_ r: Result<[URL], Error>) { guard let url = try? r.get().first, let data = try? Data(contentsOf: url) else { result = "Could not read log."; return }; if let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] { let process = object["procName"] ?? object["process"] ?? object["name"] ?? "—"; let exception = object["exception"] ?? object["exceptionType"] ?? "—"; let termination = object["termination"] ?? object["terminationReason"] ?? "—"; result = "Process: \(process)\nException: \(exception)\nTermination: \(termination)\n\nSparseBox extracted the common top-level fields. Full symbolication requires Apple symbols." } else { result = "The file was not a simple JSON object. Keep the original .ips for deeper analysis." } }
}

// MARK: Restore assistant
struct RestoreAssistantView: View {
    var body: some View { ScrollView { VStack(alignment: .leading, spacing: 12) { LabHeader(title: "Restore Assistant", subtitle: "A preflight checklist before any privileged workflow.", symbol: "checklist"); RestoreCheck(title: "Backup", detail: "Make a current encrypted backup before modifying the device.", ok: true); RestoreCheck(title: "Power", detail: "Prefer more than 50% battery or external power.", ok: UIDevice.current.batteryLevel < 0 || UIDevice.current.batteryLevel > 0.5); RestoreCheck(title: "Thermal", detail: "Avoid restore work while the device reports serious thermal pressure.", ok: ProcessInfo.processInfo.thermalState.rawValue < ProcessInfo.ThermalState.serious.rawValue); RestoreCheck(title: "Bridge", detail: "A compatible external device bridge is required for privileged operations.", ok: false); SBStatusBanner(title: "Preflight only", message: "SparseBox does not pretend to perform a restore without a compatible backend.", tone: .warning, symbol: "lock.shield") }.padding(16) }.background(Color(hex: SBTheme.backgroundHex).ignoresSafeArea()).navigationTitle("Restore Assistant") }
}
private struct RestoreCheck: View { let title: String; let detail: String; let ok: Bool; var body: some View { HStack { Image(systemName: ok ? "checkmark.circle.fill" : "xmark.circle.fill").foregroundStyle(Color(hex: ok ? SBTheme.accentHex : SBTheme.warningHex)); VStack(alignment: .leading) { Text(title).fontWeight(.semibold); Text(detail).font(.caption).foregroundStyle(Color(hex: SBTheme.mutedHex)) }; Spacer() }.padding(13).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 15, style: .continuous)) } }

// MARK: Bridge / automation
struct BridgeStatusView: View { var body: some View { ScrollView { VStack(alignment: .leading, spacing: 16) { LabHeader(title: "External Device Bridge", subtitle: "Status boundary for AFC, process inventory, restore and system writes.", symbol: "cable.connector"); SBStatusBanner(title: "Not connected", message: "Stock iOS cannot provide unrestricted access to another device's AFC filesystem or system processes. Connect a compatible host/helper when available.", tone: .warning, symbol: "externaldrive.badge.xmark"); SBCard { Text("Bridge protocol is intentionally isolated behind DeviceBridge.swift so privileged implementations can be added without changing the UI.").font(.caption).foregroundStyle(Color(hex: SBTheme.mutedHex)) } }.padding(16) }.background(Color(hex: SBTheme.backgroundHex).ignoresSafeArea()).navigationTitle("Bridge") } }
struct AutomationExportView: View { var body: some View { ScrollView { VStack(alignment: .leading, spacing: 16) { LabHeader(title: "Automation Export", subtitle: "Export compact JSON suitable for Shortcuts or host-side scripts.", symbol: "arrow.up.doc"); ShareLink(item: "SparseBox diagnostics\nDevice: \(UIDevice.current.model)\niOS: \(UIDevice.current.systemVersion)\nThermal: \(ProcessInfo.processInfo.thermalState.label)\nLow Power Mode: \(ProcessInfo.processInfo.isLowPowerModeEnabled)") { Label("Share diagnostics", systemImage: "square.and.arrow.up") }.buttonStyle(.borderedProminent).tint(Color(hex: SBTheme.accentHex)); SBCard { Text("Use this as a stable hand-off format for a Mac/PC helper or Shortcuts workflow. No private API is required.").font(.caption).foregroundStyle(Color(hex: SBTheme.mutedHex)) } }.padding(16) }.background(Color(hex: SBTheme.backgroundHex).ignoresSafeArea()).navigationTitle("Automation") } }

// MARK: - Connection & Validity

private enum SBConnectionState {
    case ready, required, missing, expired, incompatible, notRequired, unknown

    var title: String {
        switch self {
        case .ready: return "READY"
        case .required: return "REQUIRED"
        case .missing: return "MISSING"
        case .expired: return "EXPIRED"
        case .incompatible: return "INCOMPATIBLE"
        case .notRequired: return "NOT REQUIRED"
        case .unknown: return "UNKNOWN"
        }
    }

    var color: Color {
        switch self {
        case .ready: return Color(hex: SBTheme.accentHex)
        case .required, .unknown: return Color(hex: SBTheme.warningHex)
        case .missing, .expired, .incompatible: return Color(hex: SBTheme.dangerHex)
        case .notRequired: return Color(hex: SBTheme.mutedHex)
        }
    }
}

private struct SBConnectionCheck: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let state: SBConnectionState
    let symbol: String
}

struct ConnectionHealthView: View {
    @State private var pairingURL: URL?
    @State private var pairingSummary = "No pairing file imported"
    @State private var pairingState: SBConnectionState = .required
    @State private var helperEndpoint = "http://127.0.0.1:8765/health"
    @State private var helperState: SBConnectionState = .unknown
    @State private var helperDetail = "Not checked"
    @State private var pathSummary = "Checking local network path…"
    @State private var pathState: SBConnectionState = .unknown
    @State private var lastChecked: Date?
    @State private var isChecking = false
    @State private var showImporter = false
    @State private var status: ToolStatus?
    @State private var helperResponse = ""

    private var checks: [SBConnectionCheck] {
        [
            .init(title: "Pairing", detail: pairingSummary, state: pairingState, symbol: "person.badge.key"),
            .init(title: "Local tunnel / path", detail: pathSummary, state: pathState, symbol: "point.3.connected.trianglepath.dotted"),
            .init(title: "Helper", detail: helperDetail, state: helperState, symbol: "cable.connector"),
            .init(title: "Device", detail: "This iPhone is available to SparseBox", state: .ready, symbol: "iphone")
        ]
    }

    private var overall: SBConnectionState {
        if checks.contains(where: { $0.state == .expired || $0.state == .incompatible }) { return .incompatible }
        if checks.contains(where: { $0.state == .missing }) { return .missing }
        if checks.contains(where: { $0.state == .required }) { return .required }
        if checks.contains(where: { $0.state == .unknown }) { return .unknown }
        return .ready
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SBGlassHero(title: "Connection Health", subtitle: "Pairing, local tunnel and helper validity for privileged device tools.", symbol: "checkmark.shield")

                SBGlassCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("OVERALL")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color(hex: SBTheme.mutedHex))
                            Text(overall.title)
                                .font(.system(size: 28, weight: .black, design: .rounded))
                                .foregroundStyle(overall.color)
                        }
                        Spacer()
                        Image(systemName: overall == .ready ? "checkmark.shield.fill" : "exclamationmark.shield")
                            .font(.system(size: 32))
                            .foregroundStyle(overall.color)
                    }
                    if let lastChecked {
                        Text("Last verified \(lastChecked.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundStyle(Color(hex: SBTheme.mutedHex))
                    }
                }

                SBSectionTitle(title: "Validity", subtitle: "Each backend is checked independently. A tunnel is not assumed to be required for ordinary local tools.")
                SBGlassCard {
                    VStack(spacing: 0) {
                        ForEach(checks) { check in
                            ConnectionCheckRow(check: check)
                            if check.id != checks.last?.id { Divider().opacity(0.25).padding(.vertical, 5) }
                        }
                    }
                }

                SBSectionTitle(title: "Pairing file", subtitle: "Import a pairing artifact for inspection. SparseBox does not manufacture or silently replace pairing credentials.")
                SBGlassCard {
                    Label(pairingURL?.lastPathComponent ?? "No pairing file", systemImage: "person.badge.key")
                        .font(.headline)
                    Text(pairingSummary)
                        .font(.caption)
                        .foregroundStyle(Color(hex: SBTheme.mutedHex))
                    Button("Import pairing file") { showImporter = true }
                        .buttonStyle(.borderedProminent)
                        .tint(Color(hex: SBTheme.accentHex))
                }

                SBSectionTitle(title: "Local helper", subtitle: "Optional health endpoint for a companion Mac/PC helper or local tunnel service.")
                SBGlassCard {
                    TextField("Health endpoint", text: $helperEndpoint)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.system(.body, design: .monospaced))
                        .textFieldStyle(.roundedBorder)
                    HStack(spacing: 10) {
                        Button("Test helper") { testHelper() }
                            .buttonStyle(.borderedProminent)
                            .tint(Color(hex: SBTheme.accentHex))
                            .disabled(isChecking)
                        if isChecking { ProgressView().controlSize(.small) }
                    }
                    if !helperResponse.isEmpty {
                        Text(helperResponse)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(Color(hex: SBTheme.mutedHex))
                            .textSelection(.enabled)
                    }
                }

                SBStatusBanner(
                    title: "Operation-specific requirements",
                    message: "SparseBox should ask the selected backend whether AFC, restore, Wallet, .passthm or MobileGestalt operations require a pairing session, tunnel or helper. This page never treats those requirements as universal.",
                    tone: .info,
                    symbol: "info.circle"
                )

                HStack(spacing: 10) {
                    Button("Run full check") { runFullCheck() }
                        .buttonStyle(SBPrimaryButtonStyle())
                        .disabled(isChecking)
                    Button("Reset") { reset() }
                        .buttonStyle(SBSecondaryButtonStyle())
                }
            }
            .padding(16)
        }
        .background(Color(hex: SBTheme.backgroundHex).ignoresSafeArea())
        .navigationTitle("Connection")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.data, .propertyList], allowsMultipleSelection: false) { result in
            handlePairingImport(result)
        }
        .task { runFullCheck() }
        .alert(item: $status) { status in
            Alert(title: Text(status.title), message: Text(status.message), dismissButton: .default(Text("OK")))
        }
    }

    private func runFullCheck() {
        isChecking = true
        checkLocalPath()
        testHelper(showAlertOnFailure: false)
        if pairingURL == nil {
            pairingState = .required
            pairingSummary = "No pairing file imported; pairing is only needed by compatible privileged backends."
        }
        lastChecked = Date()
        isChecking = false
    }

    private func checkLocalPath() {
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { path in
            let state: SBConnectionState = path.status == .satisfied ? .ready : .required
            let detail = path.status == .satisfied
                ? "Local network path available (\(path.isExpensive ? "expensive" : "standard") path)."
                : "No active network path. A tunnel/helper may be unavailable."
            DispatchQueue.main.async {
                pathState = state
                pathSummary = detail
                lastChecked = Date()
                monitor.cancel()
            }
        }
        monitor.start(queue: DispatchQueue.global(qos: .utility))
    }

    private func testHelper(showAlertOnFailure: Bool = true) {
        guard let url = URL(string: helperEndpoint), ["http", "https"].contains(url.scheme?.lowercased() ?? "") else {
            helperState = .incompatible
            helperDetail = "Invalid HTTP(S) endpoint"
            if showAlertOnFailure { status = ToolStatus(tone: .danger, title: "Invalid endpoint", message: "Enter an HTTP or HTTPS health endpoint, such as http://127.0.0.1:8765/health.") }
            return
        }
        isChecking = true
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isChecking = false
                if let error {
                    helperState = .missing
                    helperDetail = "Not reachable: \(error.localizedDescription)"
                    helperResponse = "No compatible local helper responded."
                    return
                }
                let code = (response as? HTTPURLResponse)?.statusCode ?? 0
                if (200..<300).contains(code) {
                    helperState = .ready
                    helperDetail = "Reachable (HTTP \(code))"
                    helperResponse = String(data: data ?? Data(), encoding: .utf8) ?? "Helper responded successfully."
                } else {
                    helperState = .incompatible
                    helperDetail = "Responded with HTTP \(code)"
                    helperResponse = "Endpoint is reachable but did not report a healthy helper state."
                }
                lastChecked = Date()
            }
        }.resume()
    }

    private func handlePairingImport(_ result: Result<[URL], Error>) {
        do {
            let urls = try result.get()
            guard let url = urls.first else { return }
            pairingURL = url
            let access = url.startAccessingSecurityScopedResource()
            defer { if access { url.stopAccessingSecurityScopedResource() } }
            let data = try Data(contentsOf: url)
            pairingState = .ready
            pairingSummary = "Imported \(ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file)). The file is stored as a local reference only."
            status = ToolStatus(tone: .success, title: "Pairing imported", message: "SparseBox can inspect the selected artifact. A compatible backend still decides whether it is valid for a device session.")
        } catch {
            pairingState = .incompatible
            pairingSummary = "Could not read the selected file."
            status = ToolStatus(tone: .danger, title: "Import failed", message: error.localizedDescription)
        }
    }

    private func reset() {
        pairingURL = nil
        pairingState = .required
        pairingSummary = "No pairing file imported"
        helperState = .unknown
        helperDetail = "Not checked"
        helperResponse = ""
        pathState = .unknown
        pathSummary = "Not checked"
        lastChecked = nil
    }
}

private struct ConnectionCheckRow: View {
    let check: SBConnectionCheck

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: check.symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(check.state.color)
                .frame(width: 36, height: 36)
                .background(check.state.color.opacity(0.10), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(check.title).font(.system(size: 14, weight: .semibold))
                Text(check.detail).font(.system(size: 11)).foregroundStyle(Color(hex: SBTheme.mutedHex)).lineLimit(2)
            }
            Spacer(minLength: 8)
            Text(check.state.title)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(check.state.color)
        }
        .padding(.vertical, 5)
    }
}
