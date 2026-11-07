import SwiftUI

/// Layar acknowledgement: ilustrasi, judul, satu kalimat, tombol. Latar putih (Backgrounds/Light/Tertiary).
struct AcknowledgementLayout<Actions: View>: View {
    let illustration: String
    let title: String
    let message: String
    @ViewBuilder var actions: Actions

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 24)

            Image(illustration)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 370)
                .padding(.horizontal, 16)
                .scaleEffect(appeared ? 1 : 0.92)
                .opacity(appeared ? 1 : 0)
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text(title)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
            .offset(y: appeared ? 0 : 12)
            .opacity(appeared ? 1 : 0)

            Spacer(minLength: 24)

            VStack(spacing: 8) {
                actions
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            .opacity(appeared ? 1 : 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
        .sensoryFeedback(.success, trigger: appeared) { _, new in new }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.1)) {
                appeared = true
            }
        }
    }
}

/// Dibuka dari notifikasi hasil (Sketch: Ajukan Peninjauan / Peninjauan Selesai / Success).
struct ReviewCompletedScreen: View {
    @Environment(PrototypeModel.self) private var model

    var body: some View {
        AcknowledgementLayout(
            illustration: "illustration_review_completed",
            title: "Peninjauan Selesai",
            message: "Hasil peninjauan \(PrototypeModel.farmName) siap diunduh."
        ) {
            PrimaryButton(title: "Lihat & Unduh Hasil Peninjauan") {
                model.userAction { model.startDownload() }
            }
            // Component / Row Button. Riwayat Pengajuan di luar cakupan demo: kembali ke Detail Kebun.
            RowButton(title: "Riwayat Pengajuan") {
                model.fullScreen = nil
            }
        }
    }
}

/// Tampil sekali setelah unduhan selesai.
struct ResultReadyScreen: View {
    @Environment(PrototypeModel.self) private var model

    var body: some View {
        AcknowledgementLayout(
            illustration: "illustration_downloaded",
            title: "Hasil Siap Dilihat",
            message: "Hasil peninjauan \(PrototypeModel.farmName) sudah tersimpan di ponsel Anda."
        ) {
            PrimaryButton(title: "Lihat Hasil Peninjauan") {
                model.userAction { model.openSummary() }
            }
            RowButton(title: "Kembali ke Detail Kebun") {
                model.fullScreen = nil
            }
        }
    }
}
