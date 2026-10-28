
struct SBGlassCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) { content }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay { RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 1) }
            .shadow(color: .black.opacity(0.14), radius: 18, y: 8)
    }
}

struct SBGlassHero: View {
    let title: String
    let subtitle: String
    let symbol: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 25, weight: .semibold))
                .foregroundStyle(Color(hex: SBTheme.accentHex))
                .frame(width: 54, height: 54)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.title2.weight(.bold))
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(17)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color.white.opacity(0.14), lineWidth: 1) }
    }
}
import SwiftUI

struct SBCard<Content: View>: View {
    var padding: CGFloat = 15
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding(padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: SBTheme.surfaceHex))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(hex: SBTheme.borderHex), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct SBSectionTitle: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .tracking(1.2)
                .foregroundStyle(Color(hex: SBTheme.mutedHex))
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: SBTheme.mutedHex))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SBStatusBanner: View {
    let title: String
    let message: String
    var tone: StatusTone = .info
    var symbol: String? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: symbol ?? iconName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color(hex: tone.titleColorHex))
                .frame(width: 26, height: 26)
                .background(Color(hex: tone.titleColorHex).opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(message)
                    .font(.system(size: 12.5))
                    .foregroundStyle(Color(hex: SBTheme.mutedHex))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: SBTheme.surfaceRaisedHex))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: tone.titleColorHex))
                .frame(width: 3)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var iconName: String {
        switch tone {
        case .info: return "info.circle"
        case .success: return "checkmark.circle"
        case .warning: return "exclamationmark.triangle"
        case .danger: return "xmark.octagon"
        }
    }
}

struct SBToolRow: View {
    let title: String
    let subtitle: String
    let symbol: String
    var trailing: String? = nil

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color(hex: SBTheme.accentHex))
                .frame(width: 39, height: 39)
                .background(Color(hex: SBTheme.accentHex).opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: SBTheme.mutedHex))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 4)
            if let trailing {
                Text(trailing.uppercased())
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .tracking(0.5)
                    .foregroundStyle(Color(hex: SBTheme.warningHex))
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color(hex: SBTheme.mutedHex))
        }
        .padding(.vertical, 7)
        .contentShape(Rectangle())
    }
}

struct SBMetric: View {
    let value: String
    let label: String
    var color: String = SBTheme.accentHex

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(value)
                .font(.system(size: 21, weight: .bold, design: .monospaced))
                .foregroundStyle(Color(hex: color))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label.uppercased())
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .tracking(0.8)
                .foregroundStyle(Color(hex: SBTheme.mutedHex))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SBEmptyState: View {
    let symbol: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(Color(hex: SBTheme.mutedHex))
            Text(title)
                .font(.system(size: 16, weight: .semibold))
            Text(message)
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: SBTheme.mutedHex))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 18)
    }
}

struct SBPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(Color(hex: SBTheme.backgroundHex))
            .padding(.vertical, 13)
            .padding(.horizontal, 15)
            .frame(maxWidth: .infinity)
            .background(Color(hex: SBTheme.accentHex).opacity(configuration.isPressed ? 0.7 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
    }
}

struct SBSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.primary)
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .background(Color(hex: SBTheme.surfaceRaisedHex).opacity(configuration.isPressed ? 0.65 : 1))
            .overlay {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .stroke(Color(hex: SBTheme.borderHex), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
    }
}

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let r, g, b: UInt64
        switch cleaned.count {
        case 6:
            (r, g, b) = ((value >> 16) & 0xff, (value >> 8) & 0xff, value & 0xff)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: 1)
    }
}
