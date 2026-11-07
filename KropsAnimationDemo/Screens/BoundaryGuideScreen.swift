import SwiftUI
import MapKit

/// Halaman panduan sebelum petani menandai batas kebun (Sketch: Daftar Kebun / Panduan Petakan Batas / …).
/// Peta memakai MapKit (citra satelit). Halaman 1 "Perbesar Peta Dulu": gestur cubit, kamera peta mendekat. Halaman 2 "Tandai Sudut Kebun": ketuk empat sudut,
/// garis tersambung, batas tertutup lalu terisi. Kedua animasi berulang selama halamannya tampil.
enum BoundaryGuidePage: Hashable {
    case zoom
    case tap
}

struct BoundaryGuideScreen: View {
    @State var page: BoundaryGuidePage
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        GeometryReader { proxy in
            // Koordinat desain mengikuti frame Sketch 402 × 874.
            let unit = proxy.size.width / 402
            ZStack(alignment: .topLeading) {
                switch page {
                case .zoom: PinchGuide(unit: unit)
                case .tap: TapGuide(unit: unit)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
            .clipped()
        }
        .ignoresSafeArea()
        .overlay(alignment: .top) {
            // Gradasi Atas: status bar dan tombol tetap terbaca.
            LinearGradient(colors: [.black.opacity(0.4), .clear], startPoint: .top, endPoint: .bottom)
                .frame(height: 140)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
        .overlay(alignment: .bottom) {
            GuidePanel(page: page) {
                switch page {
                case .zoom: withAnimation(.smooth(duration: 0.35)) { page = .tap }
                case .tap: dismiss()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            if page == .zoom {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Lewati") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Peta

/// Peta satelit sungguhan (MapKit, gaya imagery) di sekitar kebun contoh di Malang Rapat, Bintan.
/// Interaksi dimatikan; zoom dianimasikan lewat jarak kamera. Butuh koneksi untuk memuat citra.
private struct GuideMap: View {
    let unit: CGFloat
    /// 0,83 = sebelum diperbesar, 1 = sudah diperbesar (sama dengan skala di Sketch).
    var zoom: CGFloat = 1

    /// Koordinat contoh dari Sheet / Content / Confirm Location / Current Location.
    static let farm = CLLocationCoordinate2D(latitude: 1.104730, longitude: 104.121380)
    /// Jarak kamera saat peta sudah diperbesar.
    private static let closeDistance: Double = 520

    @State private var position: MapCameraPosition = .camera(MapCamera(centerCoordinate: GuideMap.farm, distance: GuideMap.closeDistance))

    var body: some View {
        Map(position: $position, interactionModes: []) {}
            .mapStyle(.imagery(elevation: .flat))
            .mapControls {}
            .frame(width: 402 * unit, height: 874 * unit)
            .onAppear { position = camera(for: zoom) }
            .onChange(of: zoom) { old, new in
                if new > old {
                    // Membesar mengikuti gestur cubit.
                    withAnimation(.easeInOut(duration: 1)) { position = camera(for: new) }
                } else {
                    position = camera(for: new)
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    private func camera(for zoom: CGFloat) -> MapCameraPosition {
        .camera(MapCamera(centerCoordinate: Self.farm, distance: Self.closeDistance / Double(zoom)))
    }
}

// MARK: - Halaman 1: cubit untuk memperbesar

/// Dua titik jari mulai berdekatan di tengah, lalu merenggang ke posisi di Sketch sambil peta membesar 0,83 → 1.
/// Siklus: jeda 0,4 detik, merenggang easeInOut 1 detik, tahan 0,8 detik, memudar 0,3 detik.
private struct PinchGuide: View {
    let unit: CGFloat
    @State private var spread: CGFloat = 0
    @State private var guideOpacity: Double = 1

    /// Posisi akhir dua jari (pusat) dan titik tengahnya, dari frame Zoom.
    private let fingerA = CGPoint(x: 175, y: 330)
    private let fingerB = CGPoint(x: 237, y: 392)
    private var middle: CGPoint { CGPoint(x: (fingerA.x + fingerB.x) / 2, y: (fingerA.y + fingerB.y) / 2) }

    var body: some View {
        ZStack(alignment: .topLeading) {
            GuideMap(unit: unit, zoom: spread > 0.5 ? 1 : 0.83)

            Group {
                finger(at: interpolate(middle, fingerA))
                finger(at: interpolate(middle, fingerB))
                Image(systemName: "hand.pinch.fill")
                    .font(.system(size: 56 * unit))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.35), radius: 10, y: 4)
                    .position(x: 241 * unit, y: 348 * unit)
            }
            .opacity(guideOpacity)
        }
        .task { await loop() }
    }

    private func interpolate(_ from: CGPoint, _ to: CGPoint) -> CGPoint {
        let near = CGPoint(x: from.x + (to.x - from.x) * 0.25, y: from.y + (to.y - from.y) * 0.25)
        return CGPoint(x: near.x + (to.x - near.x) * spread, y: near.y + (to.y - near.y) * spread)
    }

    private func finger(at point: CGPoint) -> some View {
        Circle()
            .fill(.white)
            .frame(width: 28 * unit, height: 28 * unit)
            .background(Circle().stroke(.white.opacity(0.6), lineWidth: 1.5).frame(width: 48 * unit, height: 48 * unit))
            .position(x: point.x * unit, y: point.y * unit)
    }

    private func loop() async {
        while !Task.isCancelled {
            spread = 0
            guideOpacity = 1
            try? await Task.sleep(for: .milliseconds(400))
            withAnimation(.easeInOut(duration: 1)) { spread = 1 }
            try? await Task.sleep(for: .milliseconds(1800))
            withAnimation(.easeOut(duration: 0.3)) { guideOpacity = 0 }
            try? await Task.sleep(for: .milliseconds(300))
        }
    }
}

// MARK: - Halaman 2: ketuk sudut kebun

/// Tangan bergerak ke tiap sudut dan mengetuk: riak, titik muncul (aktif hijau), garis tergambar.
/// Setelah titik 3 ada garis putus-putus ke titik 1; titik 4 menutup batas, lalu batas terisi.
private struct TapGuide: View {
    let unit: CGFloat

    /// Sudut kebun (pusat titik) dari frame Completed.
    private let corners = [CGPoint(x: 73, y: 198), CGPoint(x: 135, y: 546), CGPoint(x: 353, y: 546), CGPoint(x: 291, y: 164)]

    @State private var shown = 0
    @State private var active: Int?
    @State private var drawn: [CGFloat] = [0, 0, 0, 0]
    @State private var showsClosingHint = false
    @State private var isFilled = false
    @State private var hand = 0
    @State private var handVisible = false
    @State private var isPressing = false
    @State private var ripple = 0
    @State private var opacity: Double = 1

    var body: some View {
        ZStack(alignment: .topLeading) {
            GuideMap(unit: unit)

            Group {
                // Isi batas
                polygon
                    .fill(.white.opacity(0.12))
                    .opacity(isFilled ? 1 : 0)
                // Garis antarsudut 1-2, 2-3, 3-4, 4-1
                ForEach(0..<4, id: \.self) { index in
                    segment(from: corners[index], to: corners[(index + 1) % 4])
                        .trim(from: 0, to: drawn[index])
                        .stroke(.white, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                }
                // Petunjuk penutup 3-1
                segment(from: corners[2], to: corners[0])
                    .stroke(.white.opacity(0.7), style: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [6, 6]))
                    .opacity(showsClosingHint ? 1 : 0)

                if let active {
                    RippleRing(unit: unit)
                        .id(ripple)
                        .position(x: corners[active - 1].x * unit, y: corners[active - 1].y * unit)
                }
                ForEach(1...4, id: \.self) { number in
                    if number <= shown {
                        CornerDot(number: number, isActive: number == active, unit: unit)
                            .position(x: corners[number - 1].x * unit, y: corners[number - 1].y * unit)
                            .transition(.scale(scale: 0.3).combined(with: .opacity))
                    }
                }
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 56 * unit))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.35), radius: 10, y: 4)
                    .scaleEffect(isPressing ? 0.88 : 1)
                    // Ujung jari tepat di sudut yang diketuk.
                    .position(x: (corners[hand].x + 22) * unit, y: (corners[hand].y + 34) * unit)
                    .opacity(handVisible ? 1 : 0)
            }
            .opacity(opacity)
        }
        .task { await loop() }
    }

    private var polygon: Path {
        Path { path in
            path.addLines(corners.map { CGPoint(x: $0.x * unit, y: $0.y * unit) })
            path.closeSubpath()
        }
    }

    private func segment(from a: CGPoint, to b: CGPoint) -> Path {
        Path { path in
            path.move(to: CGPoint(x: a.x * unit, y: a.y * unit))
            path.addLine(to: CGPoint(x: b.x * unit, y: b.y * unit))
        }
    }

    private func loop() async {
        while !Task.isCancelled {
            shown = 0; active = nil; drawn = [0, 0, 0, 0]
            showsClosingHint = false; isFilled = false; hand = 0; handVisible = false; opacity = 1
            try? await Task.sleep(for: .milliseconds(400))

            for index in 0..<4 {
                // Tangan bergerak ke sudut berikutnya.
                withAnimation(.easeInOut(duration: 0.45)) { hand = index; handVisible = true }
                try? await Task.sleep(for: .milliseconds(450))
                // Ketuk.
                withAnimation(.easeOut(duration: 0.12)) { isPressing = true }
                try? await Task.sleep(for: .milliseconds(120))
                ripple += 1
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    isPressing = false
                    shown = index + 1
                    active = index + 1
                }
                if index >= 1 {
                    withAnimation(.easeInOut(duration: 0.35)) { drawn[index - 1] = 1 }
                }
                if index == 2 {
                    withAnimation(.easeIn(duration: 0.3).delay(0.35)) { showsClosingHint = true }
                }
                if index == 3 {
                    withAnimation(.easeInOut(duration: 0.35)) { showsClosingHint = false; drawn[3] = 1 }
                    try? await Task.sleep(for: .milliseconds(350))
                    withAnimation(.easeOut(duration: 0.4)) { isFilled = true; active = nil; handVisible = false }
                }
                try? await Task.sleep(for: .milliseconds(600))
            }
            try? await Task.sleep(for: .milliseconds(1200))
            withAnimation(.easeOut(duration: 0.3)) { opacity = 0 }
            try? await Task.sleep(for: .milliseconds(300))
        }
    }
}

/// Titik sudut 28 pt: putih + nomor hijau; yang baru diketuk hijau + bingkai putih + nomor putih.
private struct CornerDot: View {
    let number: Int
    let isActive: Bool
    let unit: CGFloat

    var body: some View {
        Text("\(number)")
            .font(.footnote.bold())
            .foregroundStyle(isActive ? .white : Krops.primary)
            .frame(width: 28 * unit, height: 28 * unit)
            .background(isActive ? Krops.primary : .white, in: Circle())
            .overlay(Circle().stroke(.white, lineWidth: isActive ? 2 : 0))
    }
}

/// Riak ketukan: lingkaran 60 pt putih 18% dengan garis putih 60%, membesar sambil memudar sedikit.
private struct RippleRing: View {
    let unit: CGFloat
    @State private var grown = false

    var body: some View {
        Circle()
            .fill(.white.opacity(0.18))
            .overlay(Circle().stroke(.white.opacity(0.6), lineWidth: 1.5))
            .frame(width: 60 * unit, height: 60 * unit)
            .scaleEffect(grown ? 1 : 0.4)
            .opacity(grown ? 1 : 0.2)
            .onAppear {
                withAnimation(.easeOut(duration: 0.4)) { grown = true }
            }
    }
}

// MARK: - Panel

/// Sheet / Container / Small Detent (panel kaca mengambang 8 pt, sudut atas 38, bawah 54) dengan isi Boundary Guide.
private struct GuidePanel: View {
    let page: BoundaryGuidePage
    let onPrimary: () -> Void

    private var title: String { page == .zoom ? "Perbesar Peta Dulu" : "Tandai Sudut Kebun" }
    private var message: String {
        page == .zoom
            ? "Rentangkan dua jari agar sudut kebun terlihat jelas dan mudah ditandai."
            : "Ketuk peta di setiap sudut kebun. Titik akan tersambung menjadi batas kebun."
    }
    private var buttonTitle: String { page == .zoom ? "Lanjut" : "Mulai Tandai Kebun" }

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                Circle().fill(.white.opacity(page == .zoom ? 1 : 0.3)).frame(width: 7, height: 7)
                Circle().fill(.white.opacity(page == .tap ? 1 : 0.3)).frame(width: 7, height: 7)
            }
            .frame(height: 28)
            .accessibilityLabel(page == .zoom ? "Halaman 1 dari 2" : "Halaman 2 dari 2")

            VStack(spacing: 6) {
                Text(title).font(.title2.bold())
                Text(message).font(.body)
            }
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 8)
            .id(page)
            .transition(.opacity)

            Button(action: onPrimary) {
                Text(buttonTitle).frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
            .tint(Krops.primary)
        }
        .padding(.top, 10)
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
        .glassEffect(.regular.tint(Krops.deep.opacity(0.3)), in: UnevenRoundedRectangle(
            topLeadingRadius: 38, bottomLeadingRadius: 54, bottomTrailingRadius: 54, topTrailingRadius: 38, style: .continuous
        ))
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
        .ignoresSafeArea(edges: .bottom)
    }
}

#Preview {
    NavigationStack {
        BoundaryGuideScreen(page: .zoom)
    }
}
