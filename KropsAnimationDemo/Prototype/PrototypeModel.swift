import SwiftUI
import Observation
import UserNotifications
import UIKit

/// Tahap kartu status di Detail Kebun (lihat data-contoh-hifid.md).
enum ReviewStage: String {
    case inReview
    case ready
    case downloading
    case downloaded
}

/// Layar penuh yang tampil di atas Detail Kebun.
enum FullScreen: String, Identifiable {
    /// Peninjauan Selesai, dibuka dari notifikasi.
    case reviewCompleted
    /// Hasil Siap Dilihat, tampil sekali setelah unduhan selesai.
    case resultReady

    var id: String { rawValue }
}

/// Titik masuk langsung ke satu animasi di demo Unduh Hasil Peninjauan (tanpa menunggu notifikasi).
enum DownloadJump {
    /// Layar Peninjauan Selesai muncul (seperti setelah notifikasi diketuk).
    case reviewCompleted
    /// Unduhan langsung berjalan: ikon badge, progres, angka MB.
    case downloading
    /// Kartu status berganti dari Pengajuan Terkirim ke Peninjauan Selesai.
    case stageChange
    /// Layar Hasil Siap Dilihat muncul.
    case resultReady
    /// Ringkasan Hasil dibuka: kartu muncul berurutan, header peta melar.
    case summary
}

enum Route: Hashable {
    /// Pengantar alur lengkap (pilih jeda notifikasi).
    case downloadIntro
    case farmDetail
    case summary
    /// Jadwal Pemupukan, dibuka dari CTA di Ringkasan Hasil.
    case schedule
    /// Profil Kebun / Detail Kebun / Profile Saved.
    case profileSaved
    /// Daftar Kebun / Panduan Petakan Batas, mulai dari halaman tertentu.
    case boundaryGuide(BoundaryGuidePage)
}

/// Pemilik seluruh state prototipe. Satu instance dibagi ke App delegate (notifikasi) dan view.
@Observable
final class PrototypeModel {
    static let shared = PrototypeModel()

    static let farmName = "Belakang Rumah"
    static let notificationID = "review-completed"

    // MARK: State

    var stage: ReviewStage
    var notificationFireDate: Date?
    var completedAt: Date?
    var downloadedAt: Date?

    var fullScreen: FullScreen?
    var path: [Route] = []
    /// Animasi yang sedang didemokan dari daftar. `nil` = alur lengkap.
    /// Saat fokus, tombol di luar animasi itu tidak menjalankan apa-apa.
    private(set) var focus: DownloadJump?

    /// Unduhan simulasi (MB).
    let totalMB: Double = 20
    private(set) var downloadedMB: Double = 0
    private(set) var etaSeconds: Double = 90
    var isAppActive = true

    @ObservationIgnored private var downloadTask: Task<Void, Never>?

    var progress: Double { min(downloadedMB / totalMB, 1) }

    // MARK: Init

    @ObservationIgnored private let defaults = UserDefaults.standard

    private init() {
        let defaults = UserDefaults.standard
        let stored = ReviewStage(rawValue: defaults.string(forKey: "stage") ?? "") ?? .inReview
        // Unduhan yang terputus saat aplikasi ditutup kembali ke "siap diunduh".
        stage = stored == .downloading ? .ready : stored
        notificationFireDate = defaults.object(forKey: "fireDate") as? Date
        completedAt = defaults.object(forKey: "completedAt") as? Date
        downloadedAt = defaults.object(forKey: "downloadedAt") as? Date
    }

    private func persist() {
        defaults.set(stage.rawValue, forKey: "stage")
        defaults.set(notificationFireDate, forKey: "fireDate")
        defaults.set(completedAt, forKey: "completedAt")
        defaults.set(downloadedAt, forKey: "downloadedAt")
    }

    // MARK: Skenario

    /// Meminta izin, menjadwalkan notifikasi "Peninjauan Selesai", lalu masuk ke Detail Kebun (In Review).
    /// - Returns: `false` jika izin notifikasi ditolak.
    @discardableResult
    func start(after delay: TimeInterval) async -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        guard granted else { return false }
        await scheduleNotification(after: delay)
        focus = nil
        stage = .inReview
        path = [.farmDetail]
        persist()
        return true
    }

    func scheduleNotification(after delay: TimeInterval) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.notificationID])
        center.removeDeliveredNotifications(withIdentifiers: [Self.notificationID])

        let content = UNMutableNotificationContent()
        content.title = "Peninjauan Selesai"
        content.body = "Hasil peninjauan \(Self.farmName) siap diunduh."
        content.sound = .default
        content.interruptionLevel = .active
        content.threadIdentifier = "review"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(delay, 1), repeats: false)
        try? await center.add(UNNotificationRequest(identifier: Self.notificationID, content: content, trigger: trigger))
        notificationFireDate = Date().addingTimeInterval(delay)
        persist()
    }

    /// Petani mengetuk notifikasi.
    func handleNotificationTap() {
        if stage == .inReview {
            stage = .ready
            completedAt = notificationFireDate ?? .now
        }
        persist()
        guard stage == .ready else { return }
        if !path.contains(.farmDetail) { path = [.farmDetail] }
        fullScreen = .reviewCompleted
    }

    /// Petani membuka aplikasi tanpa lewat notifikasi: kartu langsung menampilkan "Peninjauan Selesai".
    func refreshAfterBecomingActive() {
        guard focus == nil, stage == .inReview, let fire = notificationFireDate, fire <= .now else { return }
        withAnimation(.smooth) {
            stage = .ready
            completedAt = fire
        }
        persist()
    }

    // MARK: Lompat ke animasi

    /// Menyiapkan state tepat sebelum animasi, lalu memutarnya setelah layar tampil.
    func jump(to target: DownloadJump) {
        downloadTask?.cancel()
        downloadTask = nil
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
        fullScreen = nil
        downloadedMB = 0
        notificationFireDate = nil
        focus = target

        switch target {
        case .stageChange:
            stage = .inReview
            completedAt = nil
            downloadedAt = nil
        case .reviewCompleted, .downloading:
            stage = .ready
            completedAt = .now
            downloadedAt = nil
        case .resultReady, .summary:
            stage = .downloaded
            completedAt = .now
            downloadedAt = .now
        }
        // Ringkasan Hasil dibuka langsung; animasi lain terjadi di Detail Kebun.
        path = target == .summary ? [.summary] : [.farmDetail]
        persist()

        Task { [weak self] in
            // Beri waktu Detail Kebun tampil agar animasinya terlihat dari awal.
            try? await Task.sleep(for: .milliseconds(700))
            guard let self else { return }
            switch target {
            case .reviewCompleted:
                self.fullScreen = .reviewCompleted
            case .downloading:
                self.startDownload()
            case .stageChange:
                withAnimation(.smooth) {
                    self.stage = .ready
                    self.completedAt = .now
                }
                self.persist()
            case .resultReady:
                self.fullScreen = .resultReady
            case .summary:
                break
            }
        }
    }

    /// Aksi tombol di layar demo. Saat fokus ke satu animasi, tombol lain tidak menjalankan apa-apa
    /// kecuali menutup layar penuh yang sedang tampil.
    func userAction(_ action: () -> Void) {
        guard focus == nil else {
            fullScreen = nil
            return
        }
        action()
    }

    // MARK: Unduhan

    func startDownload() {
        fullScreen = nil
        downloadedMB = 0
        etaSeconds = 90
        withAnimation(.smooth) { stage = .downloading }
        downloadTask?.cancel()
        downloadTask = Task { [weak self] in await self?.runDownload() }
    }

    func cancelDownload() {
        downloadTask?.cancel()
        downloadTask = nil
        withAnimation(.smooth) {
            stage = .ready
            downloadedMB = 0
        }
        persist()
    }

    /// Unduhan simulasi dengan kecepatan tetap (±4 detik untuk 20 MB).
    /// Perkiraan waktu ditampilkan dalam skala aslinya.
    private func runDownload() async {
        let tick: Double = 0.1
        let speed: Double = 5 // MB per detik demo
        try? await Task.sleep(for: .milliseconds(250))

        while downloadedMB < totalMB {
            if Task.isCancelled { return }
            try? await Task.sleep(for: .milliseconds(Int(tick * 1000)))
            if Task.isCancelled { return }
            // Unduhan berhenti sementara saat aplikasi di latar belakang ("biarkan aplikasi tetap terbuka").
            guard isAppActive else { continue }

            let next = min(downloadedMB + speed * tick, totalMB)
            withAnimation(.linear(duration: tick)) {
                downloadedMB = next
            }
            etaSeconds = (totalMB - next) / totalMB * 90
        }
        finishDownload()
    }

    private func finishDownload() {
        downloadTask = nil
        withAnimation(.smooth) {
            stage = .downloaded
            downloadedAt = .now
        }
        persist()
        Task {
            try? await Task.sleep(for: .milliseconds(650))
            if stage == .downloaded, isAppActive, focus == nil { fullScreen = .resultReady }
        }
    }

    // MARK: Navigasi

    func openSummary() {
        if fullScreen != nil {
            fullScreen = nil
            Task {
                try? await Task.sleep(for: .milliseconds(380))
                path.append(.summary)
            }
        } else {
            path.append(.summary)
        }
    }

}

// MARK: - Format teks

enum ReviewFormat {
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.dateFormat = "d MMMM yyyy, HH.mm"
        return formatter
    }()

    static func timestamp(_ date: Date?) -> String {
        "\(dateFormatter.string(from: date ?? .now)) WIB"
    }

    static func progress(downloaded: Double, total: Double) -> String {
        let percent = Int((downloaded / total * 100).rounded(.down))
        return "\(Int(downloaded.rounded(.down))) MB dari \(Int(total)) MB · \(percent)%"
    }

    static func eta(seconds: Double) -> String {
        switch seconds {
        case 75...: "Sekitar 2 menit lagi"
        case 40..<75: "Sekitar 1 menit lagi"
        case 12..<40: "Kurang dari 1 menit lagi"
        default: "Beberapa detik lagi"
        }
    }
}
