import SwiftUI

@main
struct NovaCamApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var settingsManager = SettingsManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(settingsManager)
                .preferredColorScheme(.dark)
        }
    }
}

@MainActor
final class AppState: ObservableObject {
    @Published var isCameraAuthorized = false
    @Published var isLibraryAuthorized = false
    @Published var selectedTab: AppTab = .camera
    @Published var isProcessing = false
}

enum AppTab: String, CaseIterable {
    case camera, gallery, editor, settings
    var icon: String {
        switch self { case .camera: "camera.fill"; case .gallery: "photo.on.rectangle"; case .editor: "slider.horizontal.3"; case .settings: "gearshape.fill" }
    }
}
