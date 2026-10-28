import Foundation
import Darwin
import UIKit

struct LocalDeviceSummary {
    let name: String
    let systemVersion: String
    let appVersion: String
    let processID: Int32

    static var current: LocalDeviceSummary {
        LocalDeviceSummary(
            name: UIDevice.current.model,
            systemVersion: UIDevice.current.systemVersion,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0",
            processID: getpid()
        )
    }
}

enum OSVersionCheck {
    static func components(_ version: String) -> [Int] {
        version.split(separator: ".").map { Int($0) ?? 0 }
    }

    static func compare(_ lhs: String, _ rhs: String) -> ComparisonResult {
        let a = components(lhs)
        let b = components(rhs)
        let count = max(a.count, b.count)
        for index in 0..<count {
            let left = index < a.count ? a[index] : 0
            let right = index < b.count ? b[index] : 0
            if left < right { return .orderedAscending }
            if left > right { return .orderedDescending }
        }
        return .orderedSame
    }

    static func isInRange(_ version: String, lower: String, upper: String) -> Bool {
        compare(version, lower) != .orderedAscending && compare(version, upper) != .orderedDescending
    }
}

enum LocalFileService {
    static func listDirectory(_ url: URL) throws -> [FileEntry] {
        let urls = try FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )
        return try urls.map { child in
            let values = try child.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey])
            return FileEntry(
                url: child,
                isDirectory: values.isDirectory ?? false,
                size: Int64(values.fileSize ?? 0),
                modified: values.contentModificationDate
            )
        }
        .sorted {
            if $0.isDirectory != $1.isDirectory { return $0.isDirectory && !$1.isDirectory }
            return $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }

    static func importDirectory(_ sourceURL: URL) throws -> URL {
        let fileManager = FileManager.default
        let documents = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let targetRoot = documents.appendingPathComponent("SparseBox", isDirectory: true).appendingPathComponent("RestoreQueue", isDirectory: true)
        try fileManager.createDirectory(at: targetRoot, withIntermediateDirectories: true)
        let safeName = sourceURL.lastPathComponent.isEmpty ? "payload.bin" : sourceURL.lastPathComponent
        var target = targetRoot.appendingPathComponent(safeName)
        if fileManager.fileExists(atPath: target.path) {
            target = targetRoot.appendingPathComponent("\(UUID().uuidString.prefix(8))_\(safeName)")
        }
        try fileManager.copyItem(at: sourceURL, to: target)
        return target
    }

    static func profileMetadata(from data: Data) -> (name: String?, uuid: String?, teamName: String?, expiry: Date?) {
        // Provisioning profiles are CMS-wrapped plists. This best-effort reader extracts
        // the embedded XML plist when present, without relying on private Security APIs.
        let raw = String(decoding: data, as: UTF8.self)
        guard let start = raw.range(of: "<plist"), let end = raw.range(of: "</plist>", range: start.lowerBound..<raw.endIndex) else {
            return (nil, nil, nil, nil)
        }
        let plistText = String(raw[start.lowerBound..<end.upperBound])
        guard let plistData = plistText.data(using: .utf8),
              let object = try? PropertyListSerialization.propertyList(from: plistData, options: [], format: nil),
              let dictionary = object as? [String: Any] else {
            return (nil, nil, nil, nil)
        }
        return (
            dictionary["Name"] as? String,
            dictionary["UUID"] as? String,
            dictionary["TeamName"] as? String,
            dictionary["ExpirationDate"] as? Date
        )
    }

    static func profileDirectory() throws -> URL {
        let documents = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let directory = documents.appendingPathComponent("SparseBox", isDirectory: true).appendingPathComponent("Profiles", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    static func persistProfile(sourceURL: URL, data: Data) throws -> URL {
        let directory = try profileDirectory()
        let baseName = sourceURL.lastPathComponent.isEmpty ? "profile.mobileprovision" : sourceURL.lastPathComponent
        var destination = directory.appendingPathComponent(baseName)
        if FileManager.default.fileExists(atPath: destination.path) {
            destination = directory.appendingPathComponent("\(UUID().uuidString.prefix(8))_\(baseName)")
        }
        try data.write(to: destination, options: .atomic)
        return destination
    }
}
