import SwiftUI

/// Profil Kebun / Detail Kebun / Profile Saved.
/// Demo: sheet formulir hanya berisi tombol Simpan Profil Kebun. Setelah disimpan, sheet tertutup,
/// layar bergulir ke Data Kebun, lalu sorotan muncul dan bergoyang singkat bersama haptic sukses.
struct ProfileSavedScreen: View {
    @State private var showsForm = false
    @State private var isHighlighted = false
    @State private var highlightTrigger = 0

    private let dataSectionID = "data-kebun"

    var body: some View {
        ScrollViewReader { proxy in
        ScrollView {
            VStack(spacing: 0) {
                FarmMapHeader()
                FarmSizeCard()
                    .padding(.horizontal, 16)
                    .padding(.top, -44)

                VStack(spacing: 8) {
                    ReadyForReviewCard()
                    FarmDataSection(brandIcons: true, isHighlighted: isHighlighted, highlightTrigger: highlightTrigger)
                        .id(dataSectionID)
                        // Sorotan hilang setelah salah satu baris diketuk.
                        .simultaneousGesture(TapGesture().onEnded {
                            guard isHighlighted else { return }
                            withAnimation(.smooth(duration: 0.35)) { isHighlighted = false }
                        })
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 16)
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(Krops.groupedBackground)
        .farmToolbar()
        // Haptic sukses berbarengan dengan goyang, saat sorotan sudah terlihat.
        .sensoryFeedback(.success, trigger: highlightTrigger)
        .sheet(isPresented: $showsForm) {
            ProfileFormSheet { save(scrollingWith: proxy) }
        }
        .task {
            // Demo dimulai dari formulir yang sedang terbuka.
            try? await Task.sleep(for: .milliseconds(350))
            showsForm = true
        }
        }
    }

    /// Urutan: sheet tertutup → gulir otomatis ke Data Kebun → sorotan masuk → goyang + haptic sukses.
    private func save(scrollingWith proxy: ScrollViewProxy) {
        showsForm = false
        Task {
            // 1. Tunggu sheet tertutup.
            try? await Task.sleep(for: .milliseconds(450))
            // 2. Gulir sampai Data Kebun berada di tengah layar.
            withAnimation(.smooth(duration: 0.5)) { proxy.scrollTo(dataSectionID, anchor: .center) }
            try? await Task.sleep(for: .milliseconds(550))
            // 3. Sorotan memudar masuk.
            withAnimation(.smooth(duration: 0.4)) { isHighlighted = true }
            // 4. Goyang setelah sorotan tampil penuh, agar mata sudah tertuju ke bagian ini.
            try? await Task.sleep(for: .milliseconds(400))
            highlightTrigger += 1
        }
    }
}

/// Kartu Siap Ditinjau (Sketch: padding 24/20/20, jarak 12, radius 20).
private struct ReadyForReviewCard: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.largeTitle)
                .foregroundStyle(Krops.primary)
            Text("Kebun Siap Ditinjau")
                .font(.title2.bold())
            Text("Profil kebun sudah lengkap. Ajukan peninjauan agar petugas memeriksa seluruh pohon di kebun Anda dan memberi rekomendasi pupuk yang lebih tepat.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Button {} label: {
                HStack(spacing: 4) {
                    Text("Tentang Peninjauan Kebun")
                    Image(systemName: "info.circle")
                }
                .font(.subheadline)
                .foregroundStyle(Krops.primary)
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
            PrimaryButton(title: "Ajukan Peninjauan") {}
        }
        .padding(.top, 24)
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity)
        .background(Krops.card, in: RoundedRectangle(cornerRadius: Krops.Radius.card, style: .continuous))
    }
}

/// Pengganti formulir profil kebun: hanya tombol pemicu. Tinggi sheet mengikuti isinya.
private struct ProfileFormSheet: View {
    let onSave: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Profil Kebun")
                .font(.headline)
                .padding(.top, 20)
            Text("Formulir tidak ditampilkan di demo.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            PrimaryButton(title: "Simpan Profil Kebun", action: onSave)
                .padding(.horizontal, 16)
        }
        .padding(.bottom, 8)
        .presentationDetents([.height(200)])
    }
}

#Preview {
    NavigationStack {
        ProfileSavedScreen()
    }
    .environment(PrototypeModel.shared)
}
