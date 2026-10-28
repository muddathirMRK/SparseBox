import SwiftUI
import UIKit

private struct GestaltPlan: Codable {
    let formatVersion: Int
    let exportedAt: Date
    let deviceModel: String
    let systemVersion: String
    let selectedTweakIDs: [String]
    let customModelName: String?
    let notice: String
}

struct MobileGestaltView: View {
    @AppStorage("sparsebox.selectedTweakIDs") private var selectedIDsJSON = "[]"
    @State private var searchText = ""
    @State private var customModelName = ""
    @State private var exportURL: URL?
    @State private var status: ToolStatus?

    private var selectedIDs: Set<String> {
        let data = Data(selectedIDsJSON.utf8)
        return Set((try? JSONDecoder().decode([String].self, from: data)) ?? [])
    }

    private var filteredTweaks: [GestaltTweak] {
        guard !searchText.trimmed.isEmpty else { return GestaltCatalog.all }
        return GestaltCatalog.all.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.detail.localizedCaseInsensitiveContains(searchText) ||
            $0.category.localizedCaseInsensitiveContains(searchText) ||
            $0.id.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 17) {
                SBCard {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("MOBILEGESTALT")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .tracking(1.1)
                                .foregroundStyle(Color(hex: SBTheme.accentHex))
                            Text("Tweak plan editor")
                                .font(.system(size: 21, weight: .bold))
                            Text("\(GestaltCatalog.all.count) catalog entries · \(selectedIDs.count) selected")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(Color(hex: SBTheme.mutedHex))
                        }
                        Spacer()
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 24, weight: .light))
                            .foregroundStyle(Color(hex: SBTheme.accentHex))
                    }
                    TextField("Optional device model label", text: $customModelName)
                        .font(.system(size: 13))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(11)
                        .background(Color(hex: SBTheme.backgroundHex))
                        .clipShape(RoundedRectangle(cornerRadius: 9))
                        .overlay(RoundedRectangle(cornerRadius: 9).stroke(Color(hex: SBTheme.borderHex), lineWidth: 1))
                }

                SBStatusBanner(
                    title: "Draft only — no system writes",
                    message: "Choose entries and export a JSON plan. This app does not include a MobileGestalt writer or restore exploit. A backend must map each choice to documented keys, verify version support, preserve original values and support rollback.",
                    tone: .warning
                )

                if OSVersionCheck.compare(UIDevice.current.systemVersion, "26.2") != .orderedAscending {
                    SBStatusBanner(
                        title: "Legacy compatibility caveat",
                        message: "Public upstream notes say the legacy SparseRestore / BookRestore MobileGestalt route is unsupported on iOS 26.2 and later. Newer OS builds need a separately verified backend; this catalog does not imply support.",
                        tone: .danger
                    )
                }

                HStack(spacing: 10) {
                    Button {
                        prepareExport()
                    } label: {
                        Label("Export plan", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(SBPrimaryButtonStyle())
                    Button {
                        selectedIDsJSON = "[]"
                        exportURL = nil
                        status = ToolStatus(tone: .info, title: "Selection cleared", message: "All MobileGestalt draft selections have been removed.")
                    } label: {
                        Text("Clear")
                    }
                    .buttonStyle(SBSecondaryButtonStyle())
                    .frame(maxWidth: 90)
                }

                if let exportURL {
                    SBCard {
                        Label("Plan ready", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color(hex: SBTheme.accentHex))
                        Text(exportURL.lastPathComponent)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(Color(hex: SBTheme.mutedHex))
                        ShareLink(item: exportURL) {
                            Label("Share JSON file…", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(SBSecondaryButtonStyle())
                    }
                }

                if let status {
                    SBStatusBanner(title: status.title, message: status.message, tone: status.tone)
                }

                SBSectionTitle(title: "Catalog", subtitle: "Select the options to include in a plan. Nothing is applied.")

                ForEach(GestaltCatalog.categories, id: \.self) { category in
                    let items = filteredTweaks.filter { $0.category == category }
                    if !items.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(category.uppercased())
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .tracking(1.1)
                                .foregroundStyle(Color(hex: SBTheme.accentHex))
                                .padding(.horizontal, 2)
                            VStack(spacing: 0) {
                                ForEach(Array(items.enumerated()), id: \.element.id) { index, tweak in
                                    tweakRow(tweak)
                                    if index < items.count - 1 {
                                        Divider().overlay(Color(hex: SBTheme.borderHex)).padding(.leading, 13)
                                    }
                                }
                            }
                            .padding(.horizontal, 13)
                            .background(Color(hex: SBTheme.surfaceHex))
                            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous).stroke(Color(hex: SBTheme.borderHex), lineWidth: 1))
                        }
                    }
                }

                Text("Catalog based on publicly described SparseBox / SparseBox+ / Nugget options. It is not exhaustive, is not an exact key map, and does not assert compatibility with this device or OS build.")
                    .font(.system(size: 10))
                    .foregroundStyle(Color(hex: SBTheme.mutedHex))
                Link("Upstream SparseBox", destination: URL(string: "https://github.com/khanhduytran0/SparseBox")!)
                    .font(.system(size: 12, weight: .semibold))
                Link("SparseBox+ feature catalog", destination: URL(string: "https://github.com/darthplagueiswise/SparseBoxPlus")!)
                    .font(.system(size: 12, weight: .semibold))
            }
            .padding(16)
        }
        .background(Color(hex: SBTheme.backgroundHex).ignoresSafeArea())
        .navigationTitle("MobileGestalt")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search tweak catalog")
    }

    private func tweakRow(_ tweak: GestaltTweak) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Toggle(isOn: Binding(
                get: { selectedIDs.contains(tweak.id) },
                set: { isSelected in updateSelection(tweak.id, isSelected: isSelected) }
            )) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tweak.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text(tweak.detail)
                        .font(.system(size: 11))
                        .foregroundStyle(Color(hex: SBTheme.mutedHex))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .tint(Color(hex: SBTheme.accentHex))
            if let caution = tweak.caution {
                HStack(alignment: .top, spacing: 5) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 9))
                    Text(caution)
                        .font(.system(size: 10))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .foregroundStyle(Color(hex: SBTheme.warningHex).opacity(0.92))
                .padding(.leading, 2)
            }
        }
        .padding(.vertical, 12)
    }

    private func updateSelection(_ id: String, isSelected: Bool) {
        var values = selectedIDs
        if isSelected { values.insert(id) } else { values.remove(id) }
        let sorted = values.sorted()
        if let data = try? JSONEncoder().encode(sorted), let string = String(data: data, encoding: .utf8) {
            selectedIDsJSON = string
        }
        exportURL = nil
        status = nil
    }

    private func prepareExport() {
        do {
            let plan = GestaltPlan(
                formatVersion: 1,
                exportedAt: Date(),
                deviceModel: UIDevice.current.model,
                systemVersion: UIDevice.current.systemVersion,
                selectedTweakIDs: selectedIDs.sorted(),
                customModelName: customModelName.trimmed.isEmpty ? nil : customModelName.trimmed,
                notice: "Draft only. This file does not contain executable restore operations. Confirm each key and version against a trusted, tested backend before use."
            )
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(plan)
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("SparseBox-Gestalt-Plan-\(Int(Date().timeIntervalSince1970)).json")
            try data.write(to: url, options: .atomic)
            exportURL = url
            status = ToolStatus(tone: .success, title: "Plan exported", message: "Prepared a JSON draft with \(selectedIDs.count) selected entries. No system values were changed.")
        } catch {
            status = ToolStatus(tone: .danger, title: "Export failed", message: error.localizedDescription)
        }
    }
}
