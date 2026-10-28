import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct AirCardView: View {
    @State private var selectedSection = 0
    @State private var selectedImage: UIImage?
    @State private var importedThemeName: String?
    @State private var status: ToolStatus?
    @State private var showingImagePicker = false
    @State private var showingThemeImporter = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SBGlassHero(
                    title: "AirCard",
                    subtitle: "Wallet skins + passcode themes",
                    symbol: "creditcard.and.123"
                )

                Picker("Section", selection: $selectedSection) {
                    Text("Wallet").tag(0)
                    Text("Passcode").tag(1)
                }
                .pickerStyle(.segmented)

                if selectedSection == 0 {
                    walletSection
                } else {
                    passcodeSection
                }

                SBStatusBanner(
                    title: "Device bridge",
                    message: "The editor, previews and package handling work locally. Flashing Apple system caches requires the compatible AirCard/Airlift device bridge and pairing; iOS does not expose these paths through public APIs.",
                    tone: .warning,
                    symbol: "bolt.horizontal.circle"
                )

                if let status {
                    SBStatusBanner(title: status.title, message: status.message, tone: status.tone)
                }
            }
            .padding(16)
        }
        .navigationTitle("AirCard")
        .navigationBarTitleDisplayMode(.large)
        .fileImporter(isPresented: $showingThemeImporter, allowedContentTypes: [.data, .item], allowsMultipleSelection: false) { result in
            handleThemeImport(result)
        }
    }

    private var walletSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SBSectionTitle(title: "Wallet skins", subtitle: "Prepare artwork for Wallet-sized card backgrounds.")

            SBGlassCard {
                VStack(alignment: .leading, spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.white.opacity(0.06))
                            .aspectRatio(1.586, contentMode: .fit)
                        if let selectedImage {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .scaledToFill()
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        } else {
                            VStack(spacing: 8) {
                                Image(systemName: "creditcard")
                                    .font(.system(size: 34))
                                Text("No artwork selected")
                                    .font(.headline)
                                Text("1536 × 969 target artwork")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .foregroundStyle(.secondary)
                        }
                    }

                    HStack(spacing: 10) {
                        Button("Choose artwork", systemImage: "photo") {
                            showingImagePicker = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color(hex: SBTheme.accentHex))
                        .foregroundStyle(Color(hex: SBTheme.backgroundHex))
                        .sheet(isPresented: $showingImagePicker) {
                            PhotoPicker(image: $selectedImage)
                        }

                        Button("Clear", systemImage: "xmark") {
                            selectedImage = nil
                        }
                        .buttonStyle(.bordered)
                    }

                    Text("AirCard's published workflow uses 1536×969 @3x artwork and a 1024×646 @2x asset, with PDF artwork for some transit passes.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            SBGlassCard {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Card targeting", systemImage: "rectangle.stack.person.crop")
                        .font(.headline)
                    Text("When a compatible bridge is connected, this section can list detected cards, save original artwork, revert the last skin, and apply one skin to all selected cards.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button("Prepare wallet skin") {
                        status = ToolStatus(tone: .success, title: "Artwork ready", message: "The selected artwork is ready for the device bridge. No system cache has been modified.")
                    }
                    .buttonStyle(SBPrimaryButtonStyle())
                }
            }
        }
    }

    private var passcodeSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SBSectionTitle(title: "Passcode themes", subtitle: "Create and inspect .passthm-style themes.")

            SBGlassCard {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Image(systemName: "circle.grid.3x3.fill")
                            .font(.title2)
                            .foregroundStyle(Color(hex: SBTheme.accentHex))
                        VStack(alignment: .leading) {
                            Text("Theme workspace")
                                .font(.headline)
                            Text(importedThemeName ?? "No .passthm imported")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }

                    PasscodePreview()

                    HStack(spacing: 10) {
                        Button("Import .passthm", systemImage: "square.and.arrow.down") {
                            showingThemeImporter = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color(hex: SBTheme.accentHex))
                        .foregroundStyle(Color(hex: SBTheme.backgroundHex))

                        Button("New theme", systemImage: "plus") {
                            importedThemeName = "Untitled.passthm"
                            status = ToolStatus(tone: .success, title: "New theme", message: "A local theme workspace is ready. Add artwork and export when the package writer is connected.")
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }

            SBGlassCard {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Creator", systemImage: "wand.and.stars")
                        .font(.headline)
                    Text("Poster mode can span one image across the keypad; circle mode can frame individual keys. The UI is intentionally separated from the system flash bridge so the creator remains useful even when the exploit is patched.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    HStack {
                        Label("Poster", systemImage: "rectangle")
                        Spacer()
                        Label("Individual keys", systemImage: "circle.grid.3x3")
                    }
                    .font(.caption.weight(.semibold))
                }
            }
        }
    }

    private func handleThemeImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            importedThemeName = url.lastPathComponent
            status = ToolStatus(tone: .success, title: "Theme imported", message: "Loaded \(url.lastPathComponent). Package flashing remains bridge-dependent.")
        case .failure(let error):
            status = ToolStatus(tone: .danger, title: "Import failed", message: error.localizedDescription)
        }
    }
}

struct PasscodePreview: View {
    private let keys = ["1","2","3","4","5","6","7","8","9","0"]
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
            ForEach(keys, id: \.self) { key in
                Text(key)
                    .font(.system(size: 23, weight: .medium, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .frame(height: 62)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.16), lineWidth: 1))
            }
        }
        .padding(.vertical, 6)
    }
}

struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: PhotoPicker
        init(_ parent: PhotoPicker) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            parent.image = info[.originalImage] as? UIImage
            picker.dismiss(animated: true)
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
