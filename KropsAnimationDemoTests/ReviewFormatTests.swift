import Testing
@testable import KropsAnimationDemo

@MainActor
struct ReviewFormatTests {
    @Test func progressText() {
        #expect(ReviewFormat.progress(downloaded: 8.4, total: 20) == "8 MB dari 20 MB · 42%")
        #expect(ReviewFormat.progress(downloaded: 20, total: 20) == "20 MB dari 20 MB · 100%")
    }

    @Test func etaText() {
        #expect(ReviewFormat.eta(seconds: 90) == "Sekitar 2 menit lagi")
        #expect(ReviewFormat.eta(seconds: 50) == "Sekitar 1 menit lagi")
        #expect(ReviewFormat.eta(seconds: 20) == "Kurang dari 1 menit lagi")
        #expect(ReviewFormat.eta(seconds: 3) == "Beberapa detik lagi")
    }
}
