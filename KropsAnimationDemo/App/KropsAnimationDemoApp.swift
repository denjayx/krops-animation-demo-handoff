import SwiftUI
import UserNotifications

@main
struct KropsAnimationDemoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(PrototypeModel.shared)
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // Pakai versi completion handler, bukan async: versi async memanggil completion handler
    // dari thread latar belakang dan UIKit menghentikan aplikasi ("Call must be made on main thread").

    /// Notifikasi tetap tampil sebagai banner saat aplikasi sedang terbuka.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        DispatchQueue.main.async {
            completionHandler([.banner, .list, .sound])
        }
    }

    /// Petani mengetuk notifikasi (dari lock screen, Notification Center, atau banner).
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let identifier = response.notification.request.identifier
        DispatchQueue.main.async {
            MainActor.assumeIsolated {
                if identifier == PrototypeModel.notificationID {
                    PrototypeModel.shared.handleNotificationTap()
                }
            }
            completionHandler()
        }
    }
}

struct RootView: View {
    @Environment(PrototypeModel.self) private var model
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        @Bindable var model = model

        // Satu NavigationStack: daftar animasi adalah root, tombol back bawaan selalu kembali ke daftar.
        NavigationStack(path: $model.path) {
            LauncherScreen()
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .downloadIntro: DownloadIntroScreen()
                    case .farmDetail: FarmDetailScreen()
                    case .summary: ResultSummaryScreen()
                    case .schedule: FertilizerScheduleScreen()
                    case .profileSaved: ProfileSavedScreen()
                    case .boundaryGuide(let page): BoundaryGuideScreen(page: page)
                    }
                }
        }
        .fullScreenCover(item: $model.fullScreen) { screen in
            Group {
                switch screen {
                case .reviewCompleted: ReviewCompletedScreen()
                case .resultReady: ResultReadyScreen()
                }
            }
            .environment(model)
        }
        .onChange(of: scenePhase, initial: true) { _, phase in
            model.isAppActive = phase == .active
            if phase == .active { model.refreshAfterBecomingActive() }
        }
    }
}
