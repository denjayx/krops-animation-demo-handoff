import SwiftUI
import Observation

/// State satu pupuk di kartu periode (lihat Card / Jadwal Periode / 1 / … di Sketch).
enum StopState: Equatable {
    /// Belum gilirannya. Baris putih biasa.
    case upcoming
    /// Masih jeda setelah pupuk sebelumnya. Tombol diganti keterangan tanggal.
    case waiting(from: String)
    /// Waktunya memupuk. Kartu putih besar dengan tombol tandai.
    case ready
    /// Sudah ditandai. Baris transparan dengan centang.
    case done(on: String)
}

struct FertilizerStop: Identifiable, Equatable {
    let id: Int
    let name: String
    let weight: String
    /// Teks jeda sebelum pupuk berikutnya (nil untuk pupuk terakhir).
    let gapAfter: String?
    /// Tanggal contoh saat pupuk ini ditandai.
    let markedOn: String
    var state: StopState
}

/// Titik masuk demo Jadwal Pemupukan.
enum ScheduleJump {
    /// Alur lengkap: awal periode, sheet pengingat setelah tandai pertama, sampai kartu dilipat.
    case fullFlow
    /// Awal periode: Dolomit siap ditandai (penanda berlangsung, dan alur dari Ringkasan Hasil).
    case start
    /// Tinggal Urea yang belum ditandai: tandai untuk melihat kartu dilipat otomatis.
    case lastFertilizer
    /// Kartu sudah dilipat: ketuk untuk membuka dan melipat manual.
    case collapsed
}

/// Demo Jadwal Pemupukan.
///
/// Aturan untuk developer:
/// 1. Saat pupuk terakhir ditandai, kartu menampilkan state "Tuntas" sebentar (haptic sukses),
///    lalu dilipat otomatis setelah 0,5 detik.
/// 2. Kartu lipat bisa diketuk untuk dibuka dan dilipat lagi (haptic selection, efek tekan).
/// 3. Urutan periode tidak berubah.
@Observable
final class ScheduleDemo {
    static let shared = ScheduleDemo()

    var stops: [FertilizerStop] = ScheduleDemo.initialStops
    var isPeriodOneCollapsed = false
    /// Sheet Pengingat Pemupukan (tampil sekali setelah tandai pertama, hanya di alur lengkap).
    var showsReminder = false
    /// Alur lengkap: semua langkah tampil, termasuk sheet pengingat.
    private(set) var isFullFlow = false
    /// Pemicu haptic saat menandai.
    private(set) var markCount = 0
    /// Pemicu haptic saat kartu dibuka atau dilipat manual.
    private(set) var toggleCount = 0

    @ObservationIgnored private var pendingTask: Task<Void, Never>?

    var doneCount: Int { stops.filter { if case .done = $0.state { true } else { false } }.count }
    var isPeriodOneComplete: Bool { doneCount == stops.count }

    static let initialStops: [FertilizerStop] = [
        FertilizerStop(id: 1, name: "Dolomit", weight: "400 kg", gapAfter: "Tunggu 14 hari", markedOn: "5 Januari", state: .ready),
        FertilizerStop(id: 2, name: "NPK 15-15-15", weight: "120 kg", gapAfter: "Tunggu 1–7 hari", markedOn: "19 Januari", state: .upcoming),
        FertilizerStop(id: 3, name: "Urea", weight: "100 kg", gapAfter: nil, markedOn: "22 Januari", state: .upcoming),
    ]

    /// Tanggal paling awal pupuk berikutnya bisa ditandai (contoh data).
    private static let readyFrom = [2: "19 Januari", 3: "20 Januari"]

    // MARK: Aksi

    func mark(_ stop: FertilizerStop) {
        guard let index = stops.firstIndex(where: { $0.id == stop.id }), stops[index].state == .ready else { return }
        markCount += 1
        let isLast = index + 1 == stops.count
        withAnimation(.smooth(duration: 0.4)) {
            stops[index].state = .done(on: stops[index].markedOn)
            if !isLast {
                stops[index + 1].state = .waiting(from: Self.readyFrom[stops[index + 1].id] ?? "")
            }
        }
        if isFullFlow, index == 0 {
            // Sheet pengingat muncul setelah centang Dolomit terlihat.
            Task { [weak self] in
                try? await Task.sleep(for: .milliseconds(500))
                self?.showsReminder = true
            }
        }
        pendingTask?.cancel()
        let next = index + 1
        pendingTask = Task { [weak self] in
            // Pupuk terakhir: tampilkan "Tuntas" 0,5 detik lalu lipat. Lainnya: jeda dipercepat jadi ±1,6 detik.
            try? await Task.sleep(for: .milliseconds(isLast ? 500 : 1600))
            guard let self, !Task.isCancelled else { return }
            withAnimation(.smooth(duration: isLast ? 0.5 : 0.4)) {
                if isLast {
                    self.isPeriodOneCollapsed = true
                } else {
                    self.stops[next].state = .ready
                }
            }
        }
    }

    func toggleCollapsed() {
        guard isPeriodOneComplete else { return }
        pendingTask?.cancel()
        toggleCount += 1
        withAnimation(.smooth(duration: 0.45)) { isPeriodOneCollapsed.toggle() }
    }

    func prepare(_ jump: ScheduleJump) {
        pendingTask?.cancel()
        var next = Self.initialStops
        switch jump {
        case .start, .fullFlow:
            break
        case .lastFertilizer:
            next[0].state = .done(on: next[0].markedOn)
            next[1].state = .done(on: next[1].markedOn)
            next[2].state = .ready
        case .collapsed:
            for index in next.indices { next[index].state = .done(on: next[index].markedOn) }
        }
        stops = next
        isPeriodOneCollapsed = jump == .collapsed
        isFullFlow = jump == .fullFlow
        showsReminder = false
    }
}
