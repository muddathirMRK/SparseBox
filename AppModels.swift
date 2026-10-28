import Foundation
import UniformTypeIdentifiers

// MARK: - App theme

enum SBTheme {
    static let backgroundHex = "0C1013"
    static let surfaceHex = "151B20"
    static let surfaceRaisedHex = "1B242A"
    static let borderHex = "2B373E"
    static let accentHex = "65E6C2"
    static let warningHex = "FFC56E"
    static let dangerHex = "FF827C"
    static let mutedHex = "93A2AA"
}

// MARK: - Device state and status messages

enum StatusTone {
    case info, success, warning, danger

    var titleColorHex: String {
        switch self {
        case .info: return "65E6C2"
        case .success: return "65E6C2"
        case .warning: return "FFC56E"
        case .danger: return "FF827C"
        }
    }
}

struct ToolStatus: Identifiable {
    let id = UUID()
    let tone: StatusTone
    let title: String
    let message: String
}

struct FileEntry: Identifiable {
    let url: URL
    let isDirectory: Bool
    let size: Int64
    let modified: Date?

    var id: String { url.path }
    var name: String { url.lastPathComponent }
}

struct AppRecord: Decodable, Identifiable {
    var name: String
    var bundleID: String
    var version: String?

    var id: String { bundleID }

    enum CodingKeys: String, CodingKey {
        case name
        case bundleID = "bundleID"
        case bundleIdentifier
        case version
    }

    init(name: String, bundleID: String, version: String? = nil) {
        self.name = name
        self.bundleID = bundleID
        self.version = version
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Unknown app"
        bundleID = try container.decodeIfPresent(String.self, forKey: .bundleID)
            ?? container.decode(String.self, forKey: .bundleIdentifier)
        version = try container.decodeIfPresent(String.self, forKey: .version)
    }
}

struct ProcessRecord: Codable, Identifiable {
    var pid: Int
    var name: String
    var user: String?
    var state: String?

    var id: String { "\(pid)-\(name)" }
}

struct InventoryEnvelope<T: Decodable>: Decodable {
    let items: [T]

    init(from decoder: Decoder) throws {
        if let single = try? [T](from: decoder) {
            items = single
            return
        }
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        for key in ["items", "apps", "processes", "records", "data"] {
            if let decoded = try? container.decode([T].self, forKey: DynamicCodingKey(stringValue: key)!) {
                items = decoded
                return
            }
        }
        items = []
    }
}

struct DynamicCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int? { nil }
    init?(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { return nil }
}

struct ProfileRecord: Identifiable {
    let id = UUID()
    let fileName: String
    let fileURL: URL
    let size: Int64
    let profileName: String?
    let profileUUID: String?
    let teamName: String?
    let expirationDate: Date?

    var isExpired: Bool {
        guard let expirationDate else { return false }
        return expirationDate < Date()
    }
}

struct RestorePayload: Identifiable {
    let id = UUID()
    let url: URL
    let size: Int64
    let importedAt = Date()

    var fileName: String { url.lastPathComponent }
}

// MARK: - Restore capability model

enum RestoreMethod: String, CaseIterable, Identifiable {
    case sparseRestore = "SparseRestore"
    case bookRestore = "BookRestore"

    var id: String { rawValue }

    var detail: String {
        switch self {
        case .sparseRestore:
            return "Partial-restore workflow used by older iOS builds."
        case .bookRestore:
            return "Restore workflow used by newer supported iOS builds."
        }
    }

    var documentedRange: String {
        switch self {
        case .sparseRestore: return "Known upstream range: iOS 17.0–18.1.1"
        case .bookRestore: return "Known upstream range: iOS 18.2–26.1"
        }
    }

    var symbol: String {
        switch self {
        case .sparseRestore: return "square.stack.3d.up"
        case .bookRestore: return "books.vertical"
        }
    }
}

// MARK: - MobileGestalt catalog

struct GestaltTweak: Identifiable, Hashable {
    let id: String
    let name: String
    let detail: String
    let category: String
    let caution: String?
}

enum GestaltCatalog {
    static let all: [GestaltTweak] = [
        // Device / hardware
        .init(id: "device.modelName", name: "Device model name", detail: "Draft a model-name override for a compatible backend.", category: "Device & hardware", caution: "A label change does not turn the hardware into another model."),
        .init(id: "device.subtype", name: "Device subtype / Dynamic Island", detail: "Change the reported device subtype where supported.", category: "Device & hardware", caution: "Can cause layout problems on unsupported displays."),
        .init(id: "device.actionButton", name: "Action Button UI", detail: "Expose Action Button-related UI flags.", category: "Device & hardware", caution: "Hardware behaviour may not be available."),
        .init(id: "device.cameraControl", name: "Camera Control UI", detail: "Expose Camera Control-related UI flags.", category: "Device & hardware", caution: "Requires compatible hardware and system support."),
        .init(id: "device.chargeLimit", name: "Charge limit settings", detail: "Expose charge-limit settings where supported.", category: "Device & hardware", caution: nil),
        .init(id: "device.bootChime", name: "Boot chime", detail: "Expose boot-chime configuration.", category: "Device & hardware", caution: nil),
        .init(id: "device.crashDetection", name: "Crash Detection", detail: "Toggle the reported availability flag.", category: "Device & hardware", caution: "A flag cannot add missing sensors or validate safety features."),
        .init(id: "device.applePencil", name: "Apple Pencil settings", detail: "Expose Pencil settings on otherwise unsupported configurations.", category: "Device & hardware", caution: nil),
        .init(id: "device.ipadosApps", name: "Allow iPadOS app installs", detail: "Draft the relevant compatibility flag.", category: "Device & hardware", caution: "App installation may still be blocked by other checks."),
        .init(id: "device.ipadosUI", name: "iPadOS interface flags", detail: "Draft iPad-style UI flags for testing.", category: "Device & hardware", caution: "High risk: can make the UI unusable or cause a boot loop on some configurations."),
        .init(id: "device.stageManager", name: "Stage Manager / external display", detail: "Expose Stage Manager and external-display options.", category: "Device & hardware", caution: "Requires hardware and OS support."),
        .init(id: "device.internalStorage", name: "Internal storage visibility", detail: "Expose internal storage-related views.", category: "Device & hardware", caution: "Does not grant file-system permissions to this app."),

        // Display / experience
        .init(id: "display.dynamicIsland", name: "Dynamic Island", detail: "Draft Dynamic Island eligibility flags.", category: "Display & experience", caution: "Visual compatibility varies by device and OS build."),
        .init(id: "display.alwaysOn", name: "Always-On Display", detail: "Expose Always-On Display settings.", category: "Display & experience", caution: "Requires a compatible display; unsupported hardware may drain battery or show no effect."),
        .init(id: "display.liquidGlassLowPower", name: "Liquid Glass low-performance mode", detail: "Draft the low-performance Liquid Glass flag.", category: "Display & experience", caution: "OS-build dependent."),
        .init(id: "display.noSpecularMotion", name: "Disable specular motion", detail: "Draft a Liquid Glass rendering flag.", category: "Display & experience", caution: "May not exist on every OS build."),
        .init(id: "display.noOuterRefraction", name: "Disable outer refraction", detail: "Draft a Liquid Glass rendering flag.", category: "Display & experience", caution: "May not exist on every OS build."),
        .init(id: "display.noSolariumHDR", name: "Disable Solarium HDR", detail: "Draft a Liquid Glass HDR rendering flag.", category: "Display & experience", caution: "May not exist on every OS build."),
        .init(id: "display.metalHUD", name: "Metal HUD in all apps", detail: "Expose Metal debugging overlay flags.", category: "Display & experience", caution: "Debug overlays can affect performance."),
        .init(id: "display.islandScreenshots", name: "Show Dynamic Island in screenshots", detail: "Draft screenshot rendering behaviour.", category: "Display & experience", caution: nil),
        .init(id: "display.keyFlick", name: "Key Flick keyboard", detail: "Expose iPad-style key-flick input on iPhone.", category: "Display & experience", caution: "Layout may vary by keyboard and OS version."),

        // AI / region
        .init(id: "ai.appleIntelligence", name: "Apple Intelligence eligibility", detail: "Draft eligibility flags, potentially alongside model fields.", category: "AI & region", caution: "May require supported hardware, language, region and model resources; a flag alone cannot provide them."),
        .init(id: "ai.regionRestrictions", name: "Region restriction flags", detail: "Draft region-related capability flags.", category: "AI & region", caution: "Does not alter legal, account, carrier or server-side requirements."),
        .init(id: "ai.securityResearchUI", name: "Security Research Device UI", detail: "Expose Security Research Device-related UI flags.", category: "AI & region", caution: "Does not grant research entitlements or change device security policy."),

        // System / diagnostics
        .init(id: "system.internalFeatures", name: "Internal features / settings", detail: "Expose selected internal feature flags.", category: "System & diagnostics", caution: "Internal flags are undocumented and can destabilise the system."),
        .init(id: "system.forceRTL", name: "Force right-to-left layout", detail: "Draft global layout-direction flags.", category: "System & diagnostics", caution: nil),
        .init(id: "system.buildInStatusBar", name: "Build version in status bar", detail: "Expose build/debug text in the status bar.", category: "System & diagnostics", caution: nil),
        .init(id: "system.hiddenIcons", name: "Show hidden Home Screen icons", detail: "Draft SpringBoard icon visibility flags.", category: "System & diagnostics", caution: nil),
        .init(id: "system.imessageDiagnostics", name: "iMessage diagnostics", detail: "Expose Messages diagnostic UI.", category: "System & diagnostics", caution: nil),
        .init(id: "system.idsDiagnostics", name: "IDS diagnostics", detail: "Expose IDS diagnostic UI.", category: "System & diagnostics", caution: nil),
        .init(id: "system.vcDiagnostics", name: "Video calling diagnostics", detail: "Expose video-calling diagnostic UI.", category: "System & diagnostics", caution: nil),
        .init(id: "system.appStoreGesture", name: "App Store debug gesture", detail: "Draft internal App Store debug gesture flags.", category: "System & diagnostics", caution: nil),
        .init(id: "system.notesDebug", name: "Notes debug mode", detail: "Expose Notes diagnostic controls.", category: "System & diagnostics", caution: nil),
        .init(id: "system.touchDebug", name: "Touch debug overlay", detail: "Expose touches and diagnostic overlays.", category: "System & diagnostics", caution: "May reveal touch coordinates on screen recordings."),
        .init(id: "system.pasteSound", name: "Sound on paste", detail: "Draft paste-feedback sound flags.", category: "System & diagnostics", caution: nil),
        .init(id: "system.pasteNotifications", name: "System paste notifications", detail: "Expose paste-notification behaviour.", category: "System & diagnostics", caution: nil),
        .init(id: "system.lockScreenFootnote", name: "Lock Screen footnote", detail: "Configure debug/footnote text where supported.", category: "System & diagnostics", caution: nil),
        .init(id: "system.noDimWhileCharging", name: "Prevent dimming while charging", detail: "Draft charging-related SpringBoard behaviour.", category: "System & diagnostics", caution: nil),
        .init(id: "system.noLowBatteryAlert", name: "Disable low-battery alerts", detail: "Draft notification suppression flags.", category: "System & diagnostics", caution: "Not recommended for everyday use; may hide important warnings."),
        .init(id: "system.numericSignal", name: "Numeric Wi-Fi / cellular strength", detail: "Expose numeric status-bar signal indicators.", category: "System & diagnostics", caution: nil),
        .init(id: "system.statusBarText", name: "Status-bar text and indicators", detail: "Draft carrier text, signal bars, battery text and icon visibility options.", category: "System & diagnostics", caution: "Some values may be managed by the carrier or current UI."),
        .init(id: "system.airplayStageManager", name: "AirPlay support for Stage Manager", detail: "Draft the associated compatibility flag.", category: "System & diagnostics", caution: "Requires OS and hardware support."),
        .init(id: "system.rdarFix", name: "Restore / RDAR compatibility flag", detail: "Keep a named slot for backend-supported compatibility fixes.", category: "System & diagnostics", caution: "Only use with a backend that documents the exact key and OS range."),

        // Additional public options described by related device-customisation tools.
        .init(id: "device.iphoneXGestures", name: "iPhone X gesture UI", detail: "Expose gesture-navigation flags on older device families.", category: "Status & SpringBoard", caution: "Navigation affordances may not match the display or hardware."),
        .init(id: "device.tapToWake", name: "Tap to Wake", detail: "Expose Tap to Wake on configurations where it is hidden.", category: "Status & SpringBoard", caution: "Requires compatible display hardware; the flag may have no effect."),
        .init(id: "device.collisionSOS", name: "Collision SOS eligibility", detail: "Draft Collision Detection / SOS capability flags.", category: "Status & SpringBoard", caution: "A capability flag does not add sensors or validate emergency-call behaviour."),
        .init(id: "device.spoofProfile", name: "Device spoof profile", detail: "Include a device-model/profile selection in the exported plan.", category: "Status & SpringBoard", caution: "Spoofing can make apps or system services behave incorrectly."),
        .init(id: "display.wallpaperParallax", name: "Disable wallpaper parallax", detail: "Draft wallpaper motion / parallax flags.", category: "Status & SpringBoard", caution: nil),
        .init(id: "display.lockScreenClockAnimation", name: "Lock Screen clock animation", detail: "Expose experimental Lock Screen clock animation flags.", category: "Status & SpringBoard", caution: "Internal UI flags are OS-build dependent."),
        .init(id: "display.lockScreenPageDuplication", name: "Lock Screen page duplication button", detail: "Expose experimental Lock Screen page controls.", category: "Status & SpringBoard", caution: "Internal UI flags are OS-build dependent."),
        .init(id: "display.ignoreGlassBuildCheck", name: "Ignore Liquid Glass build check", detail: "Keep a plan slot for related Liquid Glass feature gating.", category: "Status & SpringBoard", caution: "Only documented on selected iOS 26 builds; can cause visual instability."),
        .init(id: "system.euEnabler", name: "EU feature eligibility flags", detail: "Draft EU-related feature flags supported by a compatible backend.", category: "Status & SpringBoard", caution: "Does not change account, region, legal or server-side eligibility."),
        .init(id: "system.primaryCarrier", name: "Primary carrier label", detail: "Draft a custom primary carrier label.", category: "Status & SpringBoard", caution: "Carrier-managed state may overwrite the value."),
        .init(id: "system.secondaryCarrier", name: "Secondary carrier label", detail: "Draft a custom secondary carrier label.", category: "Status & SpringBoard", caution: "Carrier-managed state may overwrite the value."),
        .init(id: "system.statusBarSignalBars", name: "Wi-Fi / cellular bar count", detail: "Draft status-bar signal indicator count settings.", category: "Status & SpringBoard", caution: "Displayed bars are cosmetic and may not reflect radio quality."),
        .init(id: "system.statusBarBatteryCapacity", name: "Status-bar battery capacity", detail: "Draft battery capacity display flags.", category: "Status & SpringBoard", caution: "Display-only values may not reflect actual battery health."),
        .init(id: "system.statusBarBatteryDetail", name: "Status-bar battery detail", detail: "Expose additional battery status detail where supported.", category: "Status & SpringBoard", caution: nil),
        .init(id: "system.statusBarTimeText", name: "Custom status-bar time text", detail: "Draft replacement status-bar time text.", category: "Status & SpringBoard", caution: "Can obscure the real time in screenshots or daily use."),
        .init(id: "system.statusBarDateText", name: "Status-bar date text", detail: "Draft status-bar date text options on supported iPad builds.", category: "Status & SpringBoard", caution: "Device-family and OS-build dependent."),
        .init(id: "system.statusBarBreadcrumb", name: "Breadcrumb text", detail: "Draft text shown in return-to-app breadcrumbs.", category: "Status & SpringBoard", caution: nil),
        .init(id: "system.statusBarIconVisibility", name: "Status-bar icon visibility", detail: "Draft visibility settings for selected status-bar icons.", category: "Status & SpringBoard", caution: "Hiding an icon may obscure useful system state."),
        .init(id: "system.lockScreenIdleTimeout", name: "Lock Screen idle timeout", detail: "Draft the Lock Screen idle auto-lock interval.", category: "Status & SpringBoard", caution: "A long timeout can leave an unattended device exposed."),
        .init(id: "system.disableLockAfterRespring", name: "Disable lock after respring", detail: "Draft post-respring lock behaviour.", category: "Status & SpringBoard", caution: "May alter expected device security behaviour."),
        .init(id: "system.hideACPower", name: "Hide AC power indicator", detail: "Draft Lock Screen charging indicator visibility.", category: "Status & SpringBoard", caution: "May make charging state less obvious."),
        .init(id: "system.supervisionText", name: "Supervision text on Lock Screen", detail: "Expose a Lock Screen supervision label field.", category: "Status & SpringBoard", caution: "Do not use this to misrepresent device ownership or management status."),
        .init(id: "system.authenticationLine", name: "Authentication line on Lock Screen", detail: "Expose the red/green authentication diagnostic line.", category: "Status & SpringBoard", caution: "Diagnostic-only UI; not a security verification."),
        .init(id: "system.disableFloatingTabBar", name: "Disable floating iPad tab bar", detail: "Draft the floating tab bar display preference.", category: "Status & SpringBoard", caution: "Relevant only to supported iPad UI builds."),
        .init(id: "system.hideRespringIcon", name: "Hide respring icon", detail: "Draft the SpringBoard respring-icon visibility flag.", category: "Status & SpringBoard", caution: nil),
        .init(id: "system.kioskMode", name: "Kiosk mode eligibility", detail: "Expose a feature-flag slot for kiosk-mode testing.", category: "Status & SpringBoard", caution: "Does not provide supervised-device management or enforce kiosk security by itself.")
    ]

    static var categories: [String] {
        var seen = Set<String>()
        return all.compactMap { seen.insert($0.category).inserted ? $0.category : nil }
    }
}

extension Int64 {
    var byteCountLabel: String {
        ByteCountFormatter.string(fromByteCount: self, countStyle: .file)
    }
}

extension Date {
    var mediumDateTimeLabel: String {
        Self.sparseBoxFormatter.string(from: self)
    }

    private static let sparseBoxFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
