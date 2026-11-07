import SwiftUI

/// Pemupukan / Pengingat Pemupukan / Reminder Set.
/// Ditampilkan sekali setelah petani pertama kali menandai mulai memupuk.
///
/// Mengikuti Sketch persis: Overlay hitam 20%, Sheet / Container / Medium Detent (putih, sudut atas 38,
/// tinggi 512 = toolbar 70 + isi 442), isi Sheet / Content / Reminder Guide / Reminder Set.
/// Di aplikasi: `.sheet` dengan `.presentationDetents([.height(512)])` dan `.presentationBackground(.white)`.
struct ReminderSheetOverlay: View {
    @Binding var isPresented: Bool

    var body: some View {
        ZStack(alignment: .bottom) {
            if isPresented {
                // Sheets/Overlay/Light
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                    .onTapGesture(perform: dismiss)
                    .transition(.opacity)

                ReminderSheet(onDismiss: dismiss)
                    .transition(.move(edge: .bottom))
            }
        }
        .animation(.smooth(duration: 0.4), value: isPresented)
    }

    private func dismiss() {
        isPresented = false
    }
}

private struct ReminderSheet: View {
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar Top - Sheet / Title: tinggi 70, tombol tutup Glass 44 di x16 y16, judul Headline di tengah.
            ZStack {
                Text("Pengingat Pemupukan")
                    .font(.headline)
                    .foregroundStyle(.primary)
                HStack {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .glassEffect(.regular.interactive(), in: .circle)
                    .accessibilityLabel("Tutup")
                    Spacer()
                }
            }
            .frame(height: 44)
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .frame(height: 70, alignment: .top)

            // Isi: stack 24, padding atas 8, bawah 34, samping 16.
            VStack(spacing: 24) {
                ReminderIllustration()
                // Heading: stack 6, rata tengah. Title2 Bold, Body Labels/Secondary.
                VStack(spacing: 6) {
                    Text("Pengingat Sudah Aktif")
                        .font(.title2.bold())
                        .foregroundStyle(.primary)
                    Text("Kami akan mengingatkan Anda saat pupuk berikutnya sudah waktunya diberikan, sesuai jeda yang dianjurkan.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                // Buttons/Light/Large/Glass Prominent, tint Brand Primary, tinggi 52.
                PrimaryButton(title: "Mengerti", action: onDismiss)
            }
            .padding(.top, 8)
            .padding(.horizontal, 16)
            .padding(.bottom, 34)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 512, alignment: .top)
        .background(.white, in: UnevenRoundedRectangle(topLeadingRadius: 38, topTrailingRadius: 38, style: .continuous))
        .ignoresSafeArea(edges: .bottom)
    }
}

/// Illustration / Reminder / Reminder Set (370 × 200).
private struct ReminderIllustration: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background: Brand Soft, radius 22.
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Krops.soft)
            // Notifikasi Belakang: x40 y53, 290 lebar, putih 60%, radius 20.
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.white.opacity(0.6))
                .frame(width: 290, height: 106)
                .offset(x: 40, y: 53)
            // Notifikasi: x20 y41, 330 × 106.
            notification
                .frame(width: 330)
                .offset(x: 20, y: 41)
        }
        .frame(width: 370, height: 200)
        .accessibilityHidden(true)
    }

    /// Stack mendatar jarak 10, padding 14, putih radius 20, bayangan Brand Deep 12% y6 blur 20.
    private var notification: some View {
        HStack(alignment: .top, spacing: 10) {
            // App Icon: 38, Brand Primary radius 8, glyph kalender Subheadline Bold putih.
            Image(systemName: "calendar")
                .font(.subheadline.bold())
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(Krops.primary, in: RoundedRectangle(cornerRadius: Krops.Radius.small, style: .continuous))
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 8) {
                    Text("KROPS").font(.caption.bold())
                    Spacer(minLength: 0)
                    Text("07.00").font(.caption)
                }
                .foregroundStyle(.secondary)
                Text("Waktunya Memupuk")
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                Text("Pupuk berikutnya untuk Belakang Rumah sudah bisa diberikan.")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Krops.deep.opacity(0.12), radius: 10, y: 6)
    }
}

#Preview {
    ReminderSheetOverlay(isPresented: .constant(true))
        .background(Krops.primary)
}
