# KROPS Animation Demo

Demo SwiftUI untuk handoff animasi dan transisi KROPS (CBL 6) ke developer.
Tampilan, ukuran, warna, dan text style mengikuti HI-FID di dokumen Sketch KROPS; data mengikuti `claude/data-contoh-hifid.md`.

## Menjalankan
Buka `KropsAnimationDemo.xcodeproj` (Xcode 27, iOS 27), scheme `KropsAnimationDemo`. Jalankan di iPhone fisik agar notifikasi dan haptic terasa nyata.

## Cara memakai
Halaman depan adalah daftar animasi. Setiap baris menampilkan pratinjau elemen yang dianimasikan (komponen asli, diperkecil)
dan nama animasinya; ketuk ⓘ untuk rincian pemicu, durasi, kurva, dan haptic.
Ketuk baris (atau Putar Animasi di rincian) untuk langsung memutar animasinya: state disiapkan tepat sebelum animasi
(`PrototypeModel.jump(to:)`, `ScheduleDemo.prepare(_:)`), dan tombol lain di layar itu tidak aktif (`PrototypeModel.focus`, `userAction(_:)`).
Baris **Alur lengkap** (diberi warna pembeda: biru untuk Unduh Hasil Peninjauan, oranye untuk Jadwal Pemupukan) menjalankan flow asli dengan semua tombol aktif.
Waktu dipercepat: unduhan ±4 detik.

## Aturan untuk aplikasi
- Saat pupuk terakhir ditandai, kartu periode menampilkan state Tuntas (haptic sukses), lalu dilipat otomatis 0,5 detik kemudian.
- Urutan periode tidak berubah. Periode terlewat tidak dilipat.
- Saat periode berlangsung, titik di pill "Berlangsung" dan titik hari ini di garis rentang berdenyut terus.
- Judul di kartu lipat sejajar dengan judul di kartu terbuka (padding 16); centang dan chevron di kanan. Baris lipat dan baris judul kartu terbuka (judul + chevron) masing-masing satu tombol: efek tekan + haptic selection.
- Unduhan berhenti saat aplikasi di latar belakang.
- Panduan Petakan Batas memakai peta MapKit (citra satelit) di koordinat contoh 1.104730, 104.121380; butuh koneksi untuk memuat citra. Titik sudut digambar di atas peta dalam koordinat layar (ilustrasi).
- Setelah profil disimpan: kembali ke Detail Kebun, gulir otomatis ke Data Kebun, lalu sorotan muncul dan bergoyang sekali bersama haptic sukses. Sorotan tampil sampai salah satu baris diketuk.

## Pemetaan ke Sketch
| SwiftUI | Sketch |
|---|---|
| `PeriodCard` | Card / Jadwal Periode / n (Tiles + Panel) |
| `PeriodTileView` | Tile / Pemupukan n (termasuk Live Pill dan progres hari) |
| `StopRow` (.upcoming / .ready / .waiting / .done) | Stop / … , Stop Next / … , Stop / … (Completed) |
| Tombol tandai | Component / Fertilizer Action / Active dan / Waiting (kit Bordered Prominent Large, Symbol + Text) |
| `GapRow` | Jeda |
| `CollapsedPeriodBar` | Card / Jadwal Periode / 1 / Collapsed |
| `BoundaryGuideScreen` (`PinchGuide`, `TapGuide`, `GuidePanel`) | Daftar Kebun / Panduan Petakan Batas / Zoom, Tap, Tap Last Corner, Completed |
| `ReminderSheetOverlay` | Pemupukan / Pengingat Pemupukan / Reminder Set |
| `RowButton` | Component / Row Button |
| `FarmDataSection` | Section / Data Kebun |
| `HighlightFrame` (di `FarmDataSection`) | Sorotan / Riwayat Tersimpan (Profil Kebun / Detail Kebun / Profile Saved) |

## Struktur
- `App/` entry point, AppDelegate (notifikasi), RootView (satu NavigationStack)
- `Prototype/` state demo unduhan (`PrototypeModel`) dan jadwal (`ScheduleDemo`)
- `Screens/` daftar animasi, Detail Kebun, layar acknowledgement, Ringkasan Hasil, Jadwal Pemupukan
- `Components/FarmChrome.swift` header peta, toolbar, Kartu Ukuran, List Row, Data Kebun, badge
- `DesignSystem/Krops.swift` token warna/radius, tombol utama, Row Button
- `Resources/Assets.xcassets` aset dari Sketch (@3x)
