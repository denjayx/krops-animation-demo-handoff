import SwiftUI

/// Peta kebun di bagian atas layar (Detail Kebun, Ringkasan Hasil).
/// Melar saat ditarik ke bawah, seperti header foto di aplikasi iOS.
struct FarmMapHeader: View {
    var height: CGFloat = 360

    var body: some View {
        GeometryReader { proxy in
            let minY = proxy.frame(in: .scrollView).minY
            let stretch = max(minY, 0)
            Image("farm_map")
                .resizable()
                .scaledToFill()
                .frame(width: proxy.size.width, height: height + stretch)
                .clipped()
                .overlay(alignment: .top) {
                    // Gradasi Atas: status bar dan tombol tetap terbaca.
                    LinearGradient(colors: [.black.opacity(0.4), .clear], startPoint: .top, endPoint: .bottom)
                        .frame(height: 140)
                }
                .offset(y: -stretch)
        }
        .frame(height: height)
        .accessibilityLabel("Peta kebun \(PrototypeModel.farmName)")
    }
}

/// Judul dua baris di atas peta. Tombol kembali bawaan iOS; tombol ••• mengikuti Sketch (tanpa aksi di demo).
struct FarmToolbar: ViewModifier {
    func body(content: Content) -> some View {
        content
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            // Sketch tidak memakai efek blur di tepi atas; peta tampil penuh di belakang toolbar.
            .scrollEdgeEffectHidden(true, for: .top)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 0) {
                        Text(PrototypeModel.farmName)
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text("Malang Rapat, Bintan")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .shadow(color: .black.opacity(0.25), radius: 6, y: 1)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {} label: { Image(systemName: "ellipsis") }
                        .accessibilityLabel("Lainnya")
                }
            }
    }
}

extension View {
    func farmToolbar() -> some View {
        modifier(FarmToolbar())
    }
}

/// Kartu Ukuran: Luas · Keliling · Tahun Tanam (370×82, padding 12/14, tanpa bayangan).
struct FarmSizeCard: View {
    var body: some View {
        HStack(spacing: 8) {
            stat(icon: "square.dashed.inset.filled", label: "Luas", value: "1,7 ha")
            Divider().frame(height: 36)
            stat(icon: "square.dashed", label: "Keliling", value: "540 m")
            Divider().frame(height: 36)
            stat(icon: "calendar", label: "Tahun Tanam", value: "2016")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 14)
        .frame(height: 82)
        .background(Krops.card, in: RoundedRectangle(cornerRadius: Krops.Radius.card, style: .continuous))
    }

    private func stat(icon: String, label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Label {
                Text(label)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            } icon: {
                Image(systemName: icon)
                    .font(.footnote)
                    .foregroundStyle(Krops.primary)
            }
            .labelStyle(TightLabelStyle())
            Text(value)
                .font(.title.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct TightLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.icon
            configuration.title
        }
    }
}

/// Komponen List Row KROPS (ikon dalam lingkaran + judul + penjelasan + chevron).
struct KropsListRow: View {
    let icon: String
    let title: String
    let subtitle: String
    var tint: Color = Krops.primary
    var iconBackground: Color = Krops.soft

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(tint)
                .frame(width: 36, height: 36)
                .background(iconBackground, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 12)
            Image(systemName: "chevron.right")
                .font(.subheadline.bold())
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .background(Krops.card, in: RoundedRectangle(cornerRadius: Krops.Radius.card, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: Krops.Radius.card, style: .continuous))
    }
}

/// Lingkaran badge sukses (Element / Success Badge) dengan ikon yang bisa berganti.
struct StatusBadge: View {
    let symbol: String
    var isAnimating = false

    var body: some View {
        ZStack {
            Image("success_badge")
                .resizable()
                .frame(width: 80, height: 80)
            Image(systemName: symbol)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
                .contentTransition(.symbolEffect(.replace))
                .symbolEffect(.bounce.down, options: .repeat(.periodic(delay: 0.9)), isActive: isAnimating)
        }
        .accessibilityHidden(true)
    }
}

/// Section / Data Kebun (Component / Section Header + Component / List Row).
/// - Detail Kebun saat peninjauan: ikon Neutral, dua baris.
/// - Ringkasan Hasil: ditambah baris Pengajuan Peninjauan.
/// - Profile Saved: ikon Brand dan sorotan "Profil kebun baru saja disimpan" (Sorotan / Riwayat Tersimpan).
struct FarmDataSection: View {
    var includesSubmission = false
    var brandIcons = false
    /// Sorotan tampil sekali setelah profil disimpan, sampai salah satu baris diketuk.
    var isHighlighted = false
    /// Naik setiap kali sorotan baru muncul; memicu animasi goyang.
    var highlightTrigger = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Data Kebun")
                    .font(.title3.bold())
                    .accessibilityAddTraits(.isHeader)
                Text("Data yang Anda isi dan menjadi dasar hasil peninjauan.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            HighlightFrame(isOn: isHighlighted, trigger: highlightTrigger) {
                VStack(spacing: isHighlighted ? 4 : 8) {
                    row(icon: "square.dashed", title: "Identitas Kebun", subtitle: "Lokasi, luas, tahun tanam, jenis tanah")
                    row(icon: "doc.text", title: "Riwayat Panen dan Pemupukan", subtitle: "Dasar perhitungan kondisi hara")
                    if includesSubmission {
                        row(icon: "person", title: "Pengajuan Peninjauan", subtitle: "Narahubung dan anggaran pupuk")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func row(icon: String, title: String, subtitle: String) -> some View {
        if brandIcons {
            KropsListRow(icon: icon, title: title, subtitle: subtitle)
        } else {
            KropsListRow(icon: icon, title: title, subtitle: subtitle, tint: .secondary, iconBackground: Color(uiColor: .tertiarySystemFill))
        }
    }
}

/// Sorotan / Riwayat Tersimpan: bingkai Brand Soft radius 24 (20 + 4), padding 4, header kilau + Caption1 Bold Deep.
/// Saat muncul: bingkai memudar masuk, lalu seluruh bagian bergoyang singkat dan ikon kilau memantul.
private struct HighlightFrame<Content: View>: View {
    let isOn: Bool
    let trigger: Int
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            if isOn {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.subheadline)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(Krops.primary, Color(hex: 0xE0B000), Krops.hero)
                        .symbolEffect(.bounce, value: trigger)
                        .frame(width: 20, height: 20)
                    Text("Profil kebun baru saja disimpan")
                        .font(.caption.bold())
                        .foregroundStyle(Krops.deep)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 14)
                .padding(.top, 10)
                .padding(.bottom, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            content
        }
        .padding(.horizontal, isOn ? 4 : 0)
        .padding(.bottom, isOn ? 4 : 0)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Krops.soft)
                .opacity(isOn ? 1 : 0)
        }
        .keyframeAnimator(initialValue: Wobble(), trigger: trigger) { view, value in
            view
                .scaleEffect(value.scale)
                .rotationEffect(.degrees(value.angle))
        } keyframes: { _ in
            KeyframeTrack(\.scale) {
                CubicKeyframe(1.03, duration: 0.18)
                SpringKeyframe(1, duration: 0.45, spring: .bouncy)
            }
            KeyframeTrack(\.angle) {
                LinearKeyframe(0, duration: 0.12)
                CubicKeyframe(-1.5, duration: 0.1)
                CubicKeyframe(1.2, duration: 0.12)
                CubicKeyframe(-0.6, duration: 0.12)
                CubicKeyframe(0, duration: 0.14)
            }
        }
    }

    private struct Wobble {
        var scale: CGFloat = 1
        var angle: Double = 0
    }
}
