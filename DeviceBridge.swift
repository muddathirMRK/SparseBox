import Foundation

/// Boundary for future paired-device implementations. Keep device-specific transport
/// and privileged restore logic out of SwiftUI views.
protocol DeviceBridge {
    var name: String { get }
    func connect() async throws
    func listAFC(path: String) async throws -> [BridgeFileRecord]
    func installedApps() async throws -> [AppRecord]
    func runningProcesses() async throws -> [ProcessRecord]
    func provisioningProfiles() async throws -> [BridgeProfileRecord]
    func runRestore(method: RestoreMethod, payload: URL) async throws -> BridgeOperationResult
    func applyGestaltPlan(at url: URL) async throws -> BridgeOperationResult
}

struct BridgeFileRecord: Identifiable, Codable {
    let path: String
    let isDirectory: Bool
    let size: Int64
    var id: String { path }
}

struct BridgeProfileRecord: Identifiable, Codable {
    let uuid: String
    let name: String
    let teamName: String?
    let expirationDate: Date?
    var id: String { uuid }
}

struct BridgeOperationResult: Codable {
    let summary: String
    let verified: Bool
    let logLines: [String]
}

enum DeviceBridgeError: LocalizedError {
    case notConfigured
    case unsupportedOperation(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "No paired-device bridge is configured in this build."
        case .unsupportedOperation(let operation):
            return "The configured bridge does not support: \(operation)."
        }
    }
}

/// Explicit fallback used until a reviewed backend is added. It fails closed rather
/// than simulating successful device operations.
struct UnavailableDeviceBridge: DeviceBridge {
    let name = "No bridge"

    func connect() async throws { throw DeviceBridgeError.notConfigured }
    func listAFC(path: String) async throws -> [BridgeFileRecord] { throw DeviceBridgeError.notConfigured }
    func installedApps() async throws -> [AppRecord] { throw DeviceBridgeError.notConfigured }
    func runningProcesses() async throws -> [ProcessRecord] { throw DeviceBridgeError.notConfigured }
    func provisioningProfiles() async throws -> [BridgeProfileRecord] { throw DeviceBridgeError.notConfigured }
    func runRestore(method: RestoreMethod, payload: URL) async throws -> BridgeOperationResult { throw DeviceBridgeError.notConfigured }
    func applyGestaltPlan(at url: URL) async throws -> BridgeOperationResult { throw DeviceBridgeError.notConfigured }
}
