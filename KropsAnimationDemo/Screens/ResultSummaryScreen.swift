import SwiftUI

/// Hasil Peninjauan / Ringkasan Hasil. Data dari data-contoh-hifid.md.
struct ResultSummaryScreen: View {
    @Environment(PrototypeModel.self) private var model
    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                FarmMapHeader()

                Button {
                    model.userAction {
                        ScheduleDemo.shared.prepare(.fullFlow)
                        model.path.append(.schedule)
                    }
                } label: {
                    FertilizerScheduleCTA()
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                    .padding(.top, -87)

                VStack(spacing: 12) {
                    NutrientCard()
                        .revealed(appeared, order: 0)
                    GreennessCard()
                        .revealed(appeared, order: 1)
                    CostCard()
                        .revealed(appeared, order: 2)
                    FarmDataSection(includesSubmission: true)
                        .revealed(appeared, order: 3)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 16)
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(Krops.groupedBackground)
        .farmToolbar()
        .onAppear {
            guard !appeared else { return }
            appeared = true
        }
    }
}

private extension View {
    /// Kartu muncul berurutan saat ringkasan pertama kali dibuka.
    func revealed(_ appeared: Bool, order: Int) -> some View {
        self
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 24)
            .animation(.spring(response: 0.5, dampingFraction: 0.85).delay(0.08 * Double(order) + 0.15), value: appeared)
    }
}

// MARK: - Rekomendasi & Jadwal Pemupukan

private struct FertilizerScheduleCTA: View {
    private let periods = [("Pertama", "Jan"), ("Kedua", "Mei"), ("Ketiga", "Sep")]

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 5) {
                ForEach(periods.indices, id: \.self) { index in
                    let period = periods[index]
                    VStack(spacing: 0) {
                        Text(period.0)
                            .font(.caption2.bold())
                            .foregroundStyle(.white.opacity(0.85))
                        Text(period.1)
                            .font(.title3.bold())
                            .foregroundStyle(.white)
                        Text("2027")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 73)
                    .background(Krops.hero, in: RoundedRectangle(cornerRadius: Krops.Radius.large, style: .continuous))
                }
            }
            .padding(.horizontal, 16)
            .zIndex(1)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Rekomendasi & Jadwal Pemupukan")
                        .font(.headline)
                    Text("3 kali pemupukan di tahun 2027")
                        .font(.subheadline)
                        .opacity(0.85)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.headline)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.top, 50)
            .padding(.bottom, 14)
            .background(Krops.primary, in: RoundedRectangle(cornerRadius: Krops.Radius.card, style: .continuous))
            .padding(.top, -36)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Kartu

private struct CardHeader: View {
    let icon: String
    let title: String
    let tint: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(title)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
        .font(.headline)
        .foregroundStyle(tint)
    }
}

private struct NutrientCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            CardHeader(icon: "leaf", title: "Kondisi Hara", tint: Krops.nutrients)
            VStack(alignment: .leading, spacing: 4) {
                Text("Belum Seimbang")
                    .font(.largeTitle.bold())
                Text("Hasil dari praktik pemupukan Anda sebelumnya: dua hara kurang dan satu berlebih.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack(alignment: .top) {
                NutrientBadge(symbol: "N", status: "Kurang", name: "Nitrogen", tint: Krops.warning, mark: "arrow.down")
                NutrientBadge(symbol: "P", status: "Berlebih", name: "Fosfor", tint: Krops.caution, mark: "arrow.up")
                NutrientBadge(symbol: "K", status: "Kurang", name: "Kalium", tint: Krops.warning, mark: "arrow.down")
                NutrientBadge(symbol: "Mg", status: "Cukup", name: "Magnesium", tint: Krops.success, mark: "checkmark")
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Krops.card, in: RoundedRectangle(cornerRadius: Krops.Radius.card, style: .continuous))
    }
}

private struct NutrientBadge: View {
    let symbol: String
    let status: String
    let name: String
    let tint: Color
    let mark: String

    var body: some View {
        VStack(spacing: 0) {
            Text(symbol)
                .font(.title2.bold())
                .foregroundStyle(tint)
                .frame(width: 64, height: 64)
                .background(tint.opacity(0.16), in: Circle())
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: mark)
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(tint, in: Circle())
                        .overlay(Circle().stroke(Krops.card, lineWidth: 2))
                        .offset(x: 2, y: 2)
                }
                .padding(.bottom, 8)
            Text(status)
                .font(.footnote.bold())
                .foregroundStyle(tint)
            Text(name)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(name), \(status)")
    }
}

private struct GreennessCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CardHeader(icon: "map", title: "Kehijauan Kebun", tint: Krops.hero)
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("108")
                            .font(.largeTitle.bold())
                        Text("pohon")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    Text("dari 228 pohon terindikasi kekurangan nutrisi")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image("heatmap_thumb")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 112, height: 96)
                    .clipShape(RoundedRectangle(cornerRadius: Krops.Radius.medium, style: .continuous))
                    .accessibilityHidden(true)
            }
        }
        .cardSurface()
    }
}

private struct CostCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            CardHeader(icon: "bag.fill", title: "Perkiraan Biaya Pupuk", tint: Krops.cost)
            VStack(alignment: .leading, spacing: 4) {
                Text("Rp7.850.000")
                    .font(.largeTitle.bold())
                Text("Per tahun untuk 3 jenis pupuk")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Label("Di bawah anggaran Rp9.350.000", systemImage: "checkmark.circle.fill")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Krops.deep)
                .frame(maxWidth: .infinity)
                .frame(height: 30)
                .background(Krops.soft, in: RoundedRectangle(cornerRadius: Krops.Radius.medium, style: .continuous))
                .padding(.top, 12)
        }
        .cardSurface()
    }
}
