import SwiftUI

/// Jadwal Pemupukan. Ukuran, warna, dan text style mengikuti HI-FID Sketch:
/// frame `Pemupukan / Jadwal Pemupukan / Period Ready`, `Period Completed`, dan kartu `Card / Jadwal Periode / 1 / …`.
/// Demo: Pemupukan 1 ditandai sampai tuntas, lalu kartu dilipat otomatis.
struct FertilizerScheduleScreen: View {
    @State private var demo = ScheduleDemo.shared
    @Namespace private var periodOne

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                // Hero (Sketch: Hero, LargeTitle Bold + Subheadline putih 80%)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Jadwal Pemupukan")
                        .font(.largeTitle.bold())
                        .accessibilityAddTraits(.isHeader)
                    Text("\(PrototypeModel.farmName) · Rekomendasi untuk tahun 2027")
                        .font(.subheadline)
                        .opacity(0.8)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)

                // Section / Jadwal 2027 (jarak antarkartu 16)
                VStack(spacing: 16) {
                    periodOneCard
                    PeriodCard(
                        title: "Pemupukan 2",
                        palette: .periodTwo,
                        tile: PeriodTile(start: "Mei", end: "Juni", label: "Dimulai dalam", value: demo.isPeriodOneComplete ? "99" : "170", caption: "hari lagi")
                    ) {
                        UpcomingStops(items: [("NPK 15-15-15", "115 kg"), ("Urea", "100 kg")], gap: "Tunggu 1–7 hari", palette: .periodTwo)
                    }
                    PeriodCard(
                        title: "Pemupukan 3",
                        palette: .periodThree,
                        tile: PeriodTile(start: "September", end: "Oktober", label: "Dimulai dalam", value: demo.isPeriodOneComplete ? "222" : "293", caption: "hari lagi")
                    ) {
                        UpcomingStops(items: [("NPK 15-15-15", "115 kg"), ("Urea", "100 kg")], gap: "Tunggu 1–7 hari", palette: .periodThree)
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.top, 10)
            .padding(.bottom, 24)
        }
        .background(alignment: .top) { HeaderBand() }
        .background(Krops.groupedBackground)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sensoryFeedback(.impact(weight: .medium), trigger: demo.markCount)
        .sensoryFeedback(.success, trigger: demo.isPeriodOneComplete) { _, done in done }
        .sensoryFeedback(.selection, trigger: demo.toggleCount)
        .overlay {
            ReminderSheetOverlay(isPresented: $demo.showsReminder)
        }
    }

    // MARK: Pemupukan 1 (interaktif)

    @ViewBuilder
    private var periodOneCard: some View {
        if demo.isPeriodOneCollapsed {
            // Card / Jadwal Periode / 1 / Collapsed
            CollapsedPeriodBar(title: "Pemupukan 1", subtitle: "Selesai 22 Januari 2027", palette: .periodOne, namespace: periodOne) {
                demo.toggleCollapsed()
            }
        } else {
            PeriodCard(
                title: "Pemupukan 1",
                palette: .periodOne,
                tile: periodOneTile,
                namespace: periodOne,
                onCollapse: demo.isPeriodOneComplete ? collapseAction : nil
            ) {
                VStack(spacing: 6) {
                    ForEach(demo.stops) { stop in
                        StopRow(stop: stop, palette: .periodOne) { demo.mark(stop) }
                        if let gap = stop.gapAfter {
                            GapRow(text: gap)
                        }
                    }
                }
            }
            .transition(.opacity)
        }
    }

    private var collapseAction: () -> Void {
        { demo.toggleCollapsed() }
    }

    /// Isi tile mengikuti state kartu: Ready, Waiting/…, Completed.
    private var periodOneTile: PeriodTile {
        switch demo.doneCount {
        case 0: PeriodTile(start: "Januari", end: "Februari", label: "Berlangsung", value: "5", caption: "dari 59 hari", live: .init(day: 5, total: 59))
        case demo.stops.count: PeriodTile(start: "Januari", end: "Februari", label: "Tuntas", value: "22 Jan", caption: "2027")
        default: PeriodTile(start: "Januari", end: "Februari", label: "Dimulai", value: "5 Jan", caption: "2027")
        }
    }
}

// MARK: - Latar

/// Header Band: gradasi brand ke warna periode, dengan tiga cincin di kanan atas.
private struct HeaderBand: View {
    /// Ring 1–3 (Sketch: garis putih 8%, 1,5 pt).
    static let rings: [CGRect] = [
        CGRect(x: 300, y: -38.6, width: 220, height: 212.6),
        CGRect(x: 330, y: -9.7, width: 160, height: 154.6),
        CGRect(x: 360, y: 19.3, width: 100, height: 96.6),
    ]

    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(
                stops: [
                    .init(color: Color(hex: 0x0D5C2F), location: 0),
                    .init(color: Color(hex: 0x15803D, opacity: 0.65), location: 0.163),
                    .init(color: Color(hex: 0x15803D, opacity: 0.2), location: 0.284),
                    .init(color: Color(hex: 0x15803D, opacity: 0.08), location: 0.44),
                    .init(color: Color(hex: 0xDD6B2C, opacity: 0.09), location: 0.521),
                    .init(color: Color(hex: 0xDD6B2C, opacity: 0.06), location: 0.69),
                    .init(color: Color(hex: 0xA88D00, opacity: 0.09), location: 0.771),
                    .init(color: Color(hex: 0xA88D00, opacity: 0.04), location: 0.941),
                    .init(color: Color(hex: 0xA88D00, opacity: 0), location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 1700)

            ForEach(Self.rings.indices, id: \.self) { index in
                let ring = Self.rings[index]
                Ellipse()
                    .stroke(.white.opacity(0.08), lineWidth: 1.5)
                    .frame(width: ring.width, height: ring.height)
                    .offset(x: ring.minX, y: ring.minY)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

// MARK: - Warna periode

struct PeriodPalette {
    let panel: Color
    let tile: Color

    static let periodOne = PeriodPalette(panel: Krops.primary, tile: Krops.hero)
    static let periodTwo = PeriodPalette(panel: Color(hex: 0xDD6B2C), tile: Color(hex: 0xE5824F))
    static let periodThree = PeriodPalette(panel: Color(hex: 0xA88D00), tile: Color(hex: 0xB89F2A))
}

// MARK: - Kartu periode

struct PeriodTile {
    let start: String
    let end: String
    let label: String
    let value: String
    let caption: String
    /// Periode sedang berlangsung (Sketch: Live Pill + progres hari).
    var live: LiveDay?

    struct LiveDay {
        let day: Int
        let total: Int
    }
}

/// Kartu periode terbuka (Card / Jadwal Periode / n): Tiles 125 pt menumpuk 54 pt di atas Panel.
struct PeriodCard<Content: View>: View {
    let title: String
    let palette: PeriodPalette
    let tile: PeriodTile
    var namespace: Namespace.ID?
    var onCollapse: (() -> Void)?
    @ViewBuilder var content: Content

    private let overlap: CGFloat = 54

    /// Judul periode. Saat kartu bisa dilipat, seluruh baris judul (teks + chevron) jadi satu tombol
    /// dengan efek tekan, sama seperti baris kartu lipat.
    @ViewBuilder
    private var heading: some View {
        let row = HStack(alignment: .center) {
            Text(title)
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
                .titleMatch(in: namespace)
            Spacer()
            if onCollapse != nil {
                Image(systemName: "chevron.up")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 24, height: 44)
                    .transition(.opacity)
            }
        }
        if let onCollapse {
            Button(action: onCollapse) {
                row.contentShape(Rectangle())
            }
            .buttonStyle(PressFeedbackStyle())
            .accessibilityLabel("Lipat \(title)")
        } else {
            row
        }
    }

    var body: some View {
        VStack(spacing: -overlap) {
            PeriodTileView(tile: tile, color: palette.tile, tint: palette.panel)
                .padding(.horizontal, 16)
                .zIndex(1)

            // Panel: padding atas 54, bawah 20, samping 16; jarak Heading ke Stops 20 + 16.
            VStack(alignment: .leading, spacing: 36) {
                heading
                .padding(.top, 22)
                content
            }
            .padding(.top, overlap)
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: Krops.Radius.card, style: .continuous)
                    .fill(palette.panel)
                    .matchedGeometryEffectIfAvailable(id: "panel", in: namespace)
            }
        }
    }
}

/// Card / Jadwal Periode / 1 / Collapsed: padding 16, judul di posisi kiri yang sama dengan kartu terbuka,
/// centang dan chevron di kanan.
struct CollapsedPeriodBar: View {
    let title: String
    let subtitle: String
    let palette: PeriodPalette
    let namespace: Namespace.ID
    let onExpand: () -> Void

    var body: some View {
        Button(action: onExpand) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.title3.bold())
                        .titleMatch(in: namespace)
                    Text(subtitle)
                        .font(.subheadline)
                        .opacity(0.8)
                }
                Spacer(minLength: 8)
                RailCheck(tint: palette.panel)
                Image(systemName: "chevron.down")
                    .font(.subheadline.bold())
                    .opacity(0.7)
            }
            .foregroundStyle(.white)
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: Krops.Radius.card, style: .continuous)
                    .fill(palette.panel)
                    .matchedGeometryEffect(id: "panel", in: namespace)
            }
            .contentShape(RoundedRectangle(cornerRadius: Krops.Radius.card, style: .continuous))
        }
        .buttonStyle(PressFeedbackStyle())
        .accessibilityHint("Ketuk untuk membuka rincian")
    }
}

/// Tile / Pemupukan n: padding 16/20, radius 20, label Caption1, angka LargeTitle Bold, garis putus-putus 3/4.
struct PeriodTileView: View {
    let tile: PeriodTile
    let color: Color
    /// Warna teks dan titik pill "Berlangsung" (warna panel periode).
    var tint: Color = Krops.primary

    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .center, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Mulai").font(.caption).opacity(0.8)
                    Text(tile.start).font(.headline)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 0) {
                    if tile.live != nil {
                        // Live Pill: putih, titik berdenyut + Caption1 Bold warna periode.
                        HStack(spacing: 4) {
                            PulsingDot(color: tint, size: 6)
                            Text(tile.label).font(.caption.bold())
                        }
                        .foregroundStyle(tint)
                        .padding(.leading, 7)
                        .padding(.trailing, 8)
                        .frame(height: 16)
                        .background(.white, in: Capsule())
                        // "Hari ke-" Title3 Bold, angka hari LargeTitle Bold.
                        HStack(alignment: .lastTextBaseline, spacing: 2) {
                            Text("Hari ke-").font(.title3.bold())
                            Text(tile.value)
                                .font(.largeTitle.bold())
                                .contentTransition(.numericText())
                        }
                        .lineLimit(1)
                        .fixedSize()
                    } else {
                        Text(tile.label).font(.caption).opacity(0.8)
                        Text(tile.value)
                            .font(.largeTitle.bold())
                            .lineLimit(1)
                            .fixedSize()
                            .contentTransition(.numericText())
                    }
                    Text(tile.caption).font(.footnote.bold())
                }
                .frame(maxWidth: .infinity)

                VStack(alignment: .trailing, spacing: 0) {
                    Text("Selesai").font(.caption).opacity(0.8)
                    Text(tile.end).font(.headline)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }

            ZStack {
                DashedLine()
                    .stroke(.white.opacity(0.6), style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [3, 4]))
                    .padding(.horizontal, 4)
                HStack {
                    Circle().frame(width: 8, height: 8)
                    Spacer()
                    Circle().frame(width: 8, height: 8)
                }
                if let live = tile.live {
                    // Progres: garis solid sampai hari ini + titik hari ini yang berdenyut.
                    GeometryReader { proxy in
                        let x = 4 + (proxy.size.width - 8) * CGFloat(live.day) / CGFloat(live.total)
                        Capsule()
                            .frame(width: x - 4, height: 2)
                            .offset(x: 4, y: 3)
                        // Titik hari ini 12 pt (Sketch: Now Dot 12 + cincin 4 pt putih 35%).
                        PulsingDot(color: .white, size: 12)
                            .overlay(Circle().stroke(.white.opacity(0.35), lineWidth: 8))
                            .offset(x: x - 6, y: -2)
                    }
                }
            }
            .frame(height: 8)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(color, in: RoundedRectangle(cornerRadius: Krops.Radius.large, style: .continuous))
        .animation(.smooth, value: tile.value)
    }
}

/// Titik "sedang berlangsung": cincin memudar keluar berulang (skala 1 ke 2,6, easeOut 1,4 detik).
private struct PulsingDot: View {
    let color: Color
    let size: CGFloat
    @State private var isPulsing = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .background {
                Circle()
                    .fill(color.opacity(0.5))
                    .scaleEffect(isPulsing ? 2.6 : 1)
                    .opacity(isPulsing ? 0 : 1)
            }
            .onAppear {
                withAnimation(.easeOut(duration: 1.4).repeatForever(autoreverses: false)) {
                    isPulsing = true
                }
            }
            .accessibilityHidden(true)
    }
}

private struct DashedLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}

// MARK: - Baris pupuk

/// Rail: lingkaran 24 pt. Belum: isi warna periode 12% + nomor Footnote Bold. Sudah: putih + centang.
private struct RailNumber: View {
    let number: Int
    let tint: Color

    var body: some View {
        Text("\(number)")
            .font(.footnote.bold())
            .foregroundStyle(tint)
            .frame(width: 24, height: 24)
            .background(tint.opacity(0.12), in: Circle())
    }
}

private struct RailCheck: View {
    let tint: Color

    var body: some View {
        Image(systemName: "checkmark")
            .font(.footnote.bold())
            .foregroundStyle(tint)
            .frame(width: 24, height: 24)
            .background(.white, in: Circle())
            .accessibilityHidden(true)
    }
}

struct StopRow: View {
    let stop: FertilizerStop
    let palette: PeriodPalette
    let onMark: () -> Void

    var body: some View {
        switch stop.state {
        case .done(let date):
            // Stop / … (Completed): putih 15%, radius 20, padding 14/12/14/14.
            HStack(spacing: 10) {
                RailCheck(tint: palette.panel)
                VStack(alignment: .leading, spacing: 0) {
                    Text(stop.name).font(.title3.bold())
                    Text("Dimulai \(date)").font(.subheadline).opacity(0.8)
                }
                Spacer(minLength: 10)
                Text(stop.weight).font(.headline)
                Image(systemName: "chevron.right").font(.headline).opacity(0.7)
            }
            .foregroundStyle(.white)
            .padding(.vertical, 14)
            .padding(.leading, 12)
            .padding(.trailing, 14)
            .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: Krops.Radius.card, style: .continuous))
            .transition(.opacity)

        case .upcoming:
            // Stop / … (default): putih, radius 20.
            heading
                .padding(.vertical, 14)
                .padding(.leading, 12)
                .padding(.trailing, 14)
                .background(.white, in: RoundedRectangle(cornerRadius: Krops.Radius.card, style: .continuous))

        case .ready, .waiting:
            // Stop Next / …: putih, radius 32, padding samping/bawah 12, berisi tombol Fertilizer Action.
            VStack(spacing: 2) {
                heading
                    .padding(.vertical, 14)
                    .padding(.trailing, 2)
                action
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
            .background(.white, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
        }
    }

    private var heading: some View {
        HStack(spacing: 10) {
            RailNumber(number: stop.id, tint: palette.panel)
            Text(stop.name).font(.title3.bold())
            Spacer(minLength: 10)
            Text(stop.weight).font(.headline)
            Image(systemName: "chevron.right").font(.headline).opacity(0.6)
        }
        .foregroundStyle(palette.panel)
    }

    /// Component / Fertilizer Action / Active dan / Waiting:
    /// tombol kit Bordered Prominent Large dengan simbol + teks.
    @ViewBuilder
    private var action: some View {
        switch stop.state {
        case .waiting(let from):
            Button {} label: {
                Label("Bisa ditandai mulai \(from)", systemImage: "clock")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
            .disabled(true)
            .transition(.opacity)
        default:
            Button(action: onMark) {
                Label("Tandai Mulai Memupuk", systemImage: "checkmark.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
            .tint(palette.panel)
            .transition(.opacity)
        }
    }
}

/// Jeda: batang 4×28 putih 40% di sumbu rail, teks Subheadline putih 80% sejajar nama pupuk.
struct GapRow: View {
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(.white.opacity(0.4))
                .frame(width: 4, height: 28)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
        .padding(.leading, 14)
        .padding(.trailing, 12)
    }
}

/// Isi periode yang belum berjalan (hanya tampilan).
struct UpcomingStops: View {
    let items: [(String, String)]
    let gap: String
    let palette: PeriodPalette

    var body: some View {
        VStack(spacing: 6) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                StopRow(
                    stop: FertilizerStop(id: index + 1, name: item.0, weight: item.1, gapAfter: nil, markedOn: "", state: .upcoming),
                    palette: palette,
                    onMark: {}
                )
                if index < items.count - 1 { GapRow(text: gap) }
            }
        }
    }
}

// MARK: - Helper

/// Efek tekan untuk baris yang bisa diketuk: sedikit mengecil dan meredup saat ditekan.
struct PressFeedbackStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.smooth(duration: 0.15), value: configuration.isPressed)
    }
}

private extension View {
    /// Judul periode saat kartu dibuka/dilipat. Hanya posisi (rata kiri) yang dicocokkan dan teks memakai
    /// ukuran aslinya, jadi "Pemupukan 1" tidak terpotong selama transisi; ukuran huruf berganti lewat crossfade.
    @ViewBuilder
    func titleMatch(in namespace: Namespace.ID?) -> some View {
        let fixed = self.lineLimit(1).fixedSize()
        if let namespace {
            fixed.matchedGeometryEffect(id: "title", in: namespace, properties: .position, anchor: .leading)
        } else {
            fixed
        }
    }

    @ViewBuilder
    func matchedGeometryEffectIfAvailable(id: String, in namespace: Namespace.ID?) -> some View {
        if let namespace {
            matchedGeometryEffect(id: id, in: namespace)
        } else {
            self
        }
    }
}

#Preview {
    NavigationStack {
        FertilizerScheduleScreen()
    }
    .environment(PrototypeModel.shared)
}
