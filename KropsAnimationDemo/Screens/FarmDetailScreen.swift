import SwiftUI

/// Detail Kebun. Isi kartu status mengikuti tahap peninjauan
/// (In Review → Ready to Download → Downloading → Downloaded).
struct FarmDetailScreen: View {
    @Environment(PrototypeModel.self) private var model

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                FarmMapHeader()
                FarmSizeCard()
                    .padding(.horizontal, 16)
                    .padding(.top, -44)

                // Sketch: jarak antarbagian 8 (Kartu Ukuran → Card / Review Status → Section / Data Kebun).
                VStack(spacing: 8) {
                    ReviewStatusCard()
                    if model.stage == .inReview {
                        KropsListRow(
                            icon: "leaf",
                            title: "Lihat Profil Kebun",
                            subtitle: "Riwayat panen dan pemupukan"
                        )
                        .transition(.opacity)
                    } else {
                        // Ready to Download, Downloading, Downloaded: Section / Data Kebun.
                        FarmDataSection()
                            .transition(.opacity)
                    }
                }
                .animation(.smooth(duration: 0.35), value: model.stage == .inReview)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 16)
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(Krops.groupedBackground)
        .farmToolbar()
    }
}

struct ReviewStatusCard: View {
    @Environment(PrototypeModel.self) private var model

    var body: some View {
        VStack(spacing: 12) {
            StatusBadge(symbol: badgeSymbol, isAnimating: model.stage == .downloading)
                .padding(.top, 4)

            Text(title)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .contentTransition(.opacity)
                .id("title-\(model.stage.rawValue)")
                .transition(.opacity)

            Text(description)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .id("desc-\(model.stage.rawValue)")
                .transition(.opacity)

            if model.stage == .downloading {
                DownloadProgress()
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else if let meta {
                Text(meta)
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .transition(.opacity)
            }

            action
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity)
        .background(alignment: .top) {
            // Hero Band: hijau lembut memudar ke putih.
            LinearGradient(colors: [Krops.soft, Krops.card], startPoint: .top, endPoint: .bottom)
                .frame(height: 130)
        }
        .background(Krops.card)
        .clipShape(RoundedRectangle(cornerRadius: Krops.Radius.card, style: .continuous))
        .animation(.smooth(duration: 0.35), value: model.stage)
    }

    private var badgeSymbol: String {
        switch model.stage {
        case .inReview: "checkmark"
        case .ready: "checkmark.seal.fill"
        case .downloading: "arrow.down"
        case .downloaded: "checkmark"
        }
    }

    private var title: String {
        switch model.stage {
        case .inReview: "Pengajuan Terkirim"
        case .ready: "Peninjauan Selesai"
        case .downloading: "Mengunduh Hasil Peninjauan"
        case .downloaded: "Hasil Peninjauan Siap Dilihat"
        }
    }

    private var description: String {
        switch model.stage {
        case .inReview:
            "Petugas akan menghubungi Hendrawan Nugroho dalam 1 hari kerja untuk menentukan jadwal kunjungan ke kebun."
        case .ready:
            "Hasil peninjauan sudah tersedia. Unduh agar peta kebun dan rekomendasi pupuk bisa dibuka tanpa sinyal."
        case .downloading:
            "Biarkan aplikasi tetap terbuka sampai unduhan selesai."
        case .downloaded:
            "Peta kebun dan rekomendasi pupuk sudah tersimpan di ponsel Anda dan bisa dibuka tanpa sinyal."
        }
    }

    private var meta: String? {
        switch model.stage {
        case .inReview, .downloading: nil
        case .ready: "Selesai \(ReviewFormat.timestamp(model.completedAt)) · 20 MB"
        case .downloaded: "Diunduh \(ReviewFormat.timestamp(model.downloadedAt)) · 20 MB"
        }
    }

    @ViewBuilder
    private var action: some View {
        switch model.stage {
        case .inReview:
            PrimaryButton(title: "Lihat Status Peninjauan") {}
        case .ready:
            PrimaryButton(title: "Unduh Hasil Peninjauan") { model.userAction { model.startDownload() } }
        case .downloading:
            RowButton(title: "Batalkan Unduhan") { model.userAction { model.cancelDownload() } }
        case .downloaded:
            PrimaryButton(title: "Lihat Hasil Peninjauan") { model.userAction { model.openSummary() } }
        }
    }
}

private struct DownloadProgress: View {
    @Environment(PrototypeModel.self) private var model

    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(uiColor: .tertiarySystemFill))
                    Capsule().fill(Krops.primary)
                        .frame(width: proxy.size.width * model.progress)
                }
            }
            .frame(height: 6)
            .accessibilityElement()
            .accessibilityLabel("Unduhan")
            .accessibilityValue("\(Int(model.progress * 100)) persen")

            HStack {
                Text(ReviewFormat.progress(downloaded: model.downloadedMB, total: model.totalMB))
                Spacer()
                Text(ReviewFormat.eta(seconds: model.etaSeconds))
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            .monospacedDigit()
        }
    }
}
