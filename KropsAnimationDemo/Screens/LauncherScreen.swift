import SwiftUI

/// Halaman depan: daftar animasi untuk developer (bukan bagian dari desain aplikasi).
/// Setiap baris: pratinjau elemen yang dianimasikan + nama animasi. Ketuk baris untuk memutar,
/// ketuk ⓘ untuk melihat rincian (pemicu, durasi, kurva, haptic).
struct LauncherScreen: View {
    @Environment(PrototypeModel.self) private var model
    @State private var detail: AnimationItem?

    var body: some View {
        List {
            ForEach(AnimationCatalog.groups) { group in
                Section {
                    ForEach(group.items) { item in
                        AnimationRow(item: item, onPlay: { play(item) }, onInfo: { detail = item })
                            .listRowBackground(item.accent.map { $0.opacity(0.12) } ?? Color(uiColor: .secondarySystemGroupedBackground))
                    }
                } header: {
                    Text(group.title)
                } footer: {
                    if let footer = group.footer { Text(footer) }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Animasi KROPS")
        .tint(Krops.primary)
        .sheet(item: $detail) { item in
            AnimationDetailSheet(item: item) {
                detail = nil
                play(item)
            }
        }
    }

    private func play(_ item: AnimationItem) {
        switch item.action {
        case .flow(let route):
            model.path = [route]
        case .download(let jump):
            model.jump(to: jump)
        case .schedule(let jump):
            ScheduleDemo.shared.prepare(jump)
            model.path = [.schedule]
        }
    }
}

// MARK: - Katalog

/// Apa yang terjadi saat animasi diputar.
enum DemoAction {
    /// Membuka alur lengkap.
    case flow(Route)
    /// Langsung ke animasi di demo Unduh Hasil Peninjauan.
    case download(DownloadJump)
    /// Langsung ke animasi di demo Jadwal Pemupukan.
    case schedule(ScheduleJump)
}

struct AnimationItem: Identifiable {
    let id = UUID()
    let title: String
    /// Elemen yang dianimasikan, digambar dengan komponen aslinya.
    let preview: AnimationPreview
    /// Pemicu animasi (satu kalimat).
    let trigger: String
    /// Rincian: durasi, kurva, efek, haptic.
    let specs: [String]
    let action: DemoAction
    /// Warna pembeda baris alur lengkap (nil untuk animasi tunggal).
    var accent: Color?
}

struct AnimationGroup: Identifiable {
    let id = UUID()
    let title: String
    var footer: String?
    let items: [AnimationItem]
}

enum AnimationCatalog {
    static let groups: [AnimationGroup] = [
        AnimationGroup(
            title: "Pemetaan Kebun",
            items: [
                AnimationItem(
                    title: "Panduan perbesar peta",
                    preview: .pinchGuide,
                    trigger: "Halaman 1 panduan, sebelum petani menandai batas kebun.",
                    specs: [
                        "Dua titik jari merenggang dari tengah sambil peta membesar 0,83 ke 1 (easeInOut 1 detik).",
                        "Tahan 0,8 detik, gestur memudar 0,3 detik, lalu berulang.",
                        "Tombol Lanjut ke halaman 2; Lewati di kanan atas.",
                    ],
                    action: .flow(.boundaryGuide(.zoom))
                ),
                AnimationItem(
                    title: "Panduan tandai sudut kebun",
                    preview: .tapGuide,
                    trigger: "Halaman 2 panduan, setelah Lanjut.",
                    specs: [
                        "Tangan bergerak ke sudut (easeInOut 0,45 detik) lalu mengetuk: riak 60 pt, titik muncul (spring 0,35), garis tergambar (0,35 detik).",
                        "Setelah titik 3 muncul garis putus-putus ke titik 1; titik 4 menutup batas, lalu batas terisi putih 12% (0,4 detik).",
                        "Tahan 1,2 detik, memudar, lalu berulang.",
                    ],
                    action: .flow(.boundaryGuide(.tap))
                ),
            ]
        ),
        AnimationGroup(
            title: "Profil Kebun",
            items: [
                AnimationItem(
                    title: "Sorotan Data Kebun setelah profil disimpan",
                    preview: .profileHighlight,
                    trigger: "Ketuk Simpan Profil Kebun di sheet.",
                    specs: [
                        "Sheet tertutup, lalu layar bergulir ke Data Kebun (smooth 0,5 detik).",
                        "Sorotan memudar masuk (smooth 0,4 detik).",
                        "Bagian Data Kebun bergoyang: skala 1,03, rotasi −1,5° → 1,2° → −0,6° → 0, ±0,6 detik.",
                        "Haptic sukses bersamaan dengan goyang; ikon kilau memantul.",
                        "Sorotan hilang setelah salah satu baris diketuk.",
                    ],
                    action: .flow(.profileSaved)
                ),
            ]
        ),
        AnimationGroup(
            title: "Unduh Hasil Peninjauan",
            footer: "Unduhan dipercepat jadi ±4 detik.",
            items: [
                AnimationItem(
                    title: "Alur lengkap dari notifikasi",
                    preview: .notification,
                    trigger: "Mulai dari layar pengantar, lalu ketuk notifikasi sungguhan.",
                    specs: [
                        "Notifikasi, unduh, Hasil Siap Dilihat, sampai Ringkasan Hasil.",
                        "Semua tombol aktif.",
                    ],
                    action: .flow(.downloadIntro),
                    accent: Krops.cost
                ),
                AnimationItem(
                    title: "Peninjauan Selesai muncul",
                    preview: .reviewCompleted,
                    trigger: "Petani mengetuk notifikasi hasil peninjauan.",
                    specs: ["fullScreenCover bawaan iOS."],
                    action: .download(.reviewCompleted)
                ),
                AnimationItem(
                    title: "Kartu status berganti tahap",
                    preview: .statusCard,
                    trigger: "Hasil peninjauan terbit saat Detail Kebun terbuka.",
                    specs: ["Isi kartu berganti dengan smooth 0,35 detik; teks memudar."],
                    action: .download(.stageChange)
                ),
                AnimationItem(
                    title: "Mengunduh hasil peninjauan",
                    preview: .downloading,
                    trigger: "Ketuk Unduh Hasil Peninjauan.",
                    specs: [
                        "Ikon badge berganti (symbolEffect .replace) dan memantul tiap 0,9 detik.",
                        "Bar progres linear dengan kecepatan tetap; teks MB tanpa animasi.",
                    ],
                    action: .download(.downloading)
                ),
                AnimationItem(
                    title: "Hasil Siap Dilihat muncul",
                    preview: .resultReady,
                    trigger: "Unduhan selesai.",
                    specs: [
                        "spring(response 0,55, damping 0,8).",
                        "Ilustrasi skala 0,92 ke 1, teks naik 12 pt.",
                        "Haptic sukses.",
                    ],
                    action: .download(.resultReady)
                ),
                AnimationItem(
                    title: "Ringkasan Hasil dibuka",
                    preview: .summary,
                    trigger: "Ketuk Lihat Hasil Peninjauan.",
                    specs: [
                        "Kartu muncul berurutan: spring(response 0,5, damping 0,85), jeda 0,08 detik per kartu, naik 24 pt.",
                        "Header peta melar saat ditarik.",
                    ],
                    action: .download(.summary)
                ),
            ]
        ),
        AnimationGroup(
            title: "Jadwal Pemupukan",
            footer: "Jeda antarpupuk dipercepat jadi ±1,6 detik.",
            items: [
                AnimationItem(
                    title: "Alur lengkap Jadwal Pemupukan",
                    preview: .scheduleFlow,
                    trigger: "Periode Pemupukan 1 sedang berjalan; Dolomit siap ditandai.",
                    specs: [
                        "Tandai Dolomit: baris jadi transparan dengan centang, tile berganti, haptic impact medium.",
                        "Sheet Pengingat Pemupukan tampil sekali (kartu notifikasi turun masuk, spring 0,5).",
                        "Jeda dipercepat, lalu tandai NPK dan Urea.",
                        "Pupuk terakhir: Tuntas + haptic sukses, kartu dilipat otomatis 0,5 detik kemudian.",
                        "Semua tombol aktif.",
                    ],
                    action: .schedule(.fullFlow),
                    accent: Color(hex: 0xDD6B2C)
                ),
                AnimationItem(
                    title: "Penanda berlangsung berdenyut",
                    preview: .liveTile,
                    trigger: "Periode pemupukan sedang berjalan.",
                    specs: [
                        "Titik di pill Berlangsung dan titik hari ini di garis rentang.",
                        "Cincin skala 1 ke 2,6 sambil memudar, easeOut 1,4 detik, berulang.",
                    ],
                    action: .schedule(.start)
                ),
                AnimationItem(
                    title: "Lipat otomatis setelah pupuk terakhir ditandai",
                    preview: .lastFertilizer,
                    trigger: "Ketuk Tandai Mulai Memupuk di Urea.",
                    specs: [
                        "State Tuntas + haptic sukses.",
                        "0,5 detik kemudian kartu dilipat: matchedGeometryEffect judul (posisi) dan panel, smooth 0,5 detik.",
                    ],
                    action: .schedule(.lastFertilizer)
                ),
                AnimationItem(
                    title: "Buka dan lipat manual",
                    preview: .collapsedBar,
                    trigger: "Ketuk baris lipat untuk membuka; ketuk baris judul untuk melipat.",
                    specs: [
                        "Efek tekan: skala 0,97, opacity 0,85.",
                        "Haptic selection.",
                        "matchedGeometryEffect, smooth 0,45 detik.",
                    ],
                    action: .schedule(.collapsed)
                ),
            ]
        ),
    ]
}

// MARK: - Pratinjau elemen

/// Elemen yang dianimasikan, digambar dengan komponen yang sama dengan demo.
enum AnimationPreview {
    case profileHighlight
    case notification
    case reviewCompleted
    case statusCard
    case downloading
    case resultReady
    case summary
    case liveTile
    case lastFertilizer
    case collapsedBar
    case scheduleFlow
    case pinchGuide
    case tapGuide
}

private struct PreviewView: View {
    let preview: AnimationPreview
    @Namespace private var namespace

    var body: some View {
        switch preview {
        case .profileHighlight:
            FarmDataSection(brandIcons: true, isHighlighted: true)
                .frame(width: 370)
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.top, 8)
        case .notification:
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 120))
                .symbolRenderingMode(.palette)
                .foregroundStyle(.red, Krops.primary)
                .padding(40)
        case .reviewCompleted:
            Image("illustration_review_completed")
                .resizable()
                .scaledToFit()
                .frame(width: 370)
        case .statusCard:
            VStack(spacing: 12) {
                StatusBadge(symbol: "checkmark.seal.fill")
                Text("Peninjauan Selesai").font(.title2.bold())
            }
            .padding(24)
        case .downloading:
            VStack(spacing: 16) {
                StatusBadge(symbol: "arrow.down")
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(uiColor: .tertiarySystemFill))
                    Capsule().fill(Krops.primary).frame(width: 140)
                }
                .frame(width: 260, height: 6)
            }
            .padding(24)
        case .resultReady:
            Image("illustration_downloaded")
                .resizable()
                .scaledToFit()
                .frame(width: 370)
        case .summary:
            Image("farm_map")
                .resizable()
                .scaledToFill()
                .frame(width: 370, height: 280)
                .clipped()
        case .liveTile:
            PeriodTileView(
                tile: PeriodTile(start: "Januari", end: "Februari", label: "Berlangsung", value: "5", caption: "dari 59 hari", live: .init(day: 5, total: 59)),
                color: Krops.hero,
                tint: Krops.primary
            )
            .frame(width: 338)
            .padding(16)
        case .lastFertilizer:
            StopRow(
                stop: FertilizerStop(id: 3, name: "Urea", weight: "100 kg", gapAfter: nil, markedOn: "", state: .ready),
                palette: .periodOne,
                onMark: {}
            )
            .frame(width: 338)
            .padding(16)
            .background(Krops.primary)
        case .pinchGuide, .tapGuide:
            Image("boundary_map")
                .resizable()
                .scaledToFill()
                .frame(width: 400, height: 290)
                .clipped()
                .overlay {
                    Image(systemName: preview == .pinchGuide ? "hand.pinch.fill" : "hand.tap.fill")
                        .font(.system(size: 150))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.35), radius: 10, y: 4)
                }
        case .scheduleFlow:
            VStack(spacing: -54) {
                PeriodTileView(
                    tile: PeriodTile(start: "Januari", end: "Februari", label: "Berlangsung", value: "5", caption: "dari 59 hari", live: .init(day: 5, total: 59)),
                    color: Krops.hero,
                    tint: Krops.primary
                )
                .padding(.horizontal, 16)
                .zIndex(1)
                Krops.primary
                    .frame(height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: Krops.Radius.card, style: .continuous))
            }
            .frame(width: 370)
            .padding(16)
        case .collapsedBar:
            CollapsedPeriodBar(title: "Pemupukan 1", subtitle: "Selesai 22 Januari 2027", palette: .periodOne, namespace: namespace) {}
                .frame(width: 370)
                .padding(16)
        }
    }
}

/// Pratinjau diperkecil di dalam bingkai tetap.
/// Elemen digambar sekali ke gambar diam (ImageRenderer, kanvas 402 × 292), lalu ditampilkan sebagai Image.
/// Dengan begitu tata letak komponen asli tidak ikut memengaruhi tinggi baris List.
private struct PreviewFrame: View {
    let preview: AnimationPreview
    let width: CGFloat

    static let canvas = CGSize(width: 402, height: 292)

    var body: some View {
        Group {
            if let image = PreviewCache.image(for: preview) {
                Image(uiImage: image).resizable()
            } else {
                Krops.groupedBackground
            }
        }
        .frame(width: width, height: width * Self.canvas.height / Self.canvas.width)
        .clipShape(RoundedRectangle(cornerRadius: Krops.Radius.medium, style: .continuous))
        .accessibilityHidden(true)
    }
}

@MainActor
private enum PreviewCache {
    private static var images: [AnimationPreview: UIImage] = [:]

    static func image(for preview: AnimationPreview) -> UIImage? {
        if let cached = images[preview] { return cached }
        let renderer = ImageRenderer(content:
            PreviewView(preview: preview)
                .frame(width: PreviewFrame.canvas.width, height: PreviewFrame.canvas.height)
                .background(Krops.groupedBackground)
                .clipped()
        )
        renderer.scale = 3
        let image = renderer.uiImage
        images[preview] = image
        return image
    }
}

// MARK: - Baris dan rincian

private struct AnimationRow: View {
    let item: AnimationItem
    let onPlay: () -> Void
    let onInfo: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onPlay) {
                HStack(spacing: 12) {
                    PreviewFrame(preview: item.preview, width: 88)
                        .overlay {
                            if let accent = item.accent {
                                RoundedRectangle(cornerRadius: Krops.Radius.medium, style: .continuous)
                                    .stroke(accent, lineWidth: 2)
                            }
                        }
                    VStack(alignment: .leading, spacing: 4) {
                        if let accent = item.accent {
                            Label("Alur lengkap", systemImage: "play.fill")
                                .font(.caption.bold())
                                .foregroundStyle(accent)
                        }
                        Text(item.title)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(action: onInfo) {
                Image(systemName: "info.circle")
                    .font(.title3)
                    .foregroundStyle(item.accent ?? Krops.primary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Rincian \(item.title)")
        }
        .padding(.vertical, 2)
    }
}

/// Rincian animasi: pratinjau besar, pemicu, spesifikasi, dan tombol putar.
private struct AnimationDetailSheet: View {
    let item: AnimationItem
    let onPlay: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    PreviewFrame(preview: item.preview, width: 338)
                        .frame(maxWidth: .infinity)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
                Section("Pemicu") {
                    Text(item.trigger)
                }
                Section("Rincian") {
                    ForEach(item.specs, id: \.self) { spec in
                        Text(spec)
                    }
                }
            }
            .navigationTitle(item.title)
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                PrimaryButton(title: "Putar Animasi", action: onPlay)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            }
        }
        .tint(Krops.primary)
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Pengantar demo unduhan

/// Pengantar demo Unduh Hasil Peninjauan: memilih jeda notifikasi lalu mulai.
struct DownloadIntroScreen: View {
    @Environment(PrototypeModel.self) private var model
    @Environment(\.openURL) private var openURL

    @State private var delay: Int = 1
    @State private var isStarting = false
    @State private var showsPermissionAlert = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 64, height: 64)
                        .background(Krops.primary, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                    Text("Unduh Hasil Peninjauan")
                        .font(.largeTitle.bold())
                    Text("Simulasi dari notifikasi hasil peninjauan sampai petani melihat ringkasan hasilnya.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 18) {
                    StepRow(number: 1, text: "Ketuk Mulai. Aplikasi menampilkan Detail Kebun yang sedang ditinjau.")
                    StepRow(number: 2, text: delay == 1 ? "Notifikasi hasil peninjauan langsung masuk sebagai banner." : "Kunci iPhone atau pindah ke aplikasi lain.")
                    StepRow(number: 3, text: delay == 1 ? "Ketuk banner notifikasinya." : "Notifikasi hasil peninjauan masuk dalam \(delay) detik. Ketuk notifikasinya.")
                }
                .cardSurface(padding: 20)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Notifikasi masuk setelah")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Picker("Notifikasi masuk setelah", selection: $delay) {
                        Text("Langsung").tag(1)
                        Text("5 detik").tag(5)
                        Text("10 detik").tag(10)
                    }
                    .pickerStyle(.segmented)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(Krops.groupedBackground)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(title: isStarting ? "Menyiapkan…" : "Mulai") {
                Task { await start() }
            }
            .disabled(isStarting)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .alert("Notifikasi belum diizinkan", isPresented: $showsPermissionAlert) {
            Button("Buka Pengaturan") {
                if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
            }
            Button("Batal", role: .cancel) {}
        } message: {
            Text("Demo ini memakai notifikasi sungguhan. Izinkan notifikasi untuk KROPS di Pengaturan, lalu ketuk Mulai lagi.")
        }
    }

    private func start() async {
        isStarting = true
        let granted = await model.start(after: TimeInterval(delay))
        isStarting = false
        if !granted { showsPermissionAlert = true }
    }
}

private struct StepRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text("\(number)")
                .font(.subheadline.bold())
                .foregroundStyle(Krops.primary)
                .frame(width: 26, height: 26)
                .background(Krops.soft, in: Circle())
                .alignmentGuide(.firstTextBaseline) { $0[VerticalAlignment.center] + 5 }
            Text(text)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
