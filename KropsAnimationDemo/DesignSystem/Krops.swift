import SwiftUI

/// KROPS tokens dari Sketch (Brand Colors, Status, Corner Radius).
enum Krops {
    // Brand
    static let primary = Color(hex: 0x15803D)
    static let hero = Color(hex: 0x16A34A)
    static let deep = Color(hex: 0x0D5C2F)
    static let soft = Color(hex: 0xE7F6EC)

    // Status (selalu dengan label teks)
    static let success = Color(hex: 0x2FA04E)
    static let caution = Color(hex: 0xA88D00)
    static let warning = Color(hex: 0xDD6B2C)

    // Warna kategori Ringkasan Hasil (pola Apple Health, warna sistem)
    static let nutrients = Color(uiColor: .systemPurple)
    static let cost = Color(uiColor: .systemBlue)

    static let groupedBackground = Color(uiColor: .systemGroupedBackground)
    static let card = Color(uiColor: .secondarySystemGroupedBackground)

    enum Radius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 20
        /// Kartu di layar (sama dengan Sketch: 20).
        static let card: CGFloat = 20
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

/// Permukaan kartu putih standar KROPS.
struct CardSurface: ViewModifier {
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Krops.card, in: RoundedRectangle(cornerRadius: Krops.Radius.card, style: .continuous))
    }
}

extension View {
    func cardSurface(padding: CGFloat = 16) -> some View {
        modifier(CardSurface(padding: padding))
    }
}

/// Tombol utama: Glass Prominent dengan tint Brand Primary, tinggi 52 (Buttons/Light/Large/Glass Prominent).
struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.tint(Krops.primary).interactive(), in: .capsule)
    }
}

/// Component / Row Button (Sketch): teks Headline warna brand, tinggi 52, tanpa latar.
/// Dipakai untuk aksi sekunder di dalam kartu, mis. "Batalkan Unduhan".
struct RowButton: View {
    let title: String
    var systemImage: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title)
            }
            .font(.headline)
            .foregroundStyle(Krops.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
