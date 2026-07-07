import SwiftUI
import PhotosUI

// MARK: - Content View
struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settingsManager: SettingsManager

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            CameraView()
                .tabItem { Label("Camera", systemImage: "camera.fill") }
                .tag(AppTab.camera)

            GalleryView()
                .tabItem { Label("Gallery", systemImage: "photo.on.rectangle") }
                .tag(AppTab.gallery)

            EditorView()
                .tabItem { Label("Editor", systemImage: "slider.horizontal.3") }
                .tag(AppTab.editor)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(AppTab.settings)
        }
        .tint(.orange)
        .preferredColorScheme(settingsManager.colorTheme == .dark ? .dark : nil)
    }
}

// MARK: - Gallery
struct GalleryView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 16) {
                    Image(systemName: "photo.on.rectangle").font(.system(size: 48)).foregroundColor(.white.opacity(0.5))
                    Text("Gallery").font(.title2).foregroundColor(.white)
                    Text("Your photos will appear here").font(.body).foregroundColor(.white.opacity(0.6))
                }
            }.navigationTitle("Gallery")
        }
    }
}

// MARK: - Editor with Photo Picker
struct EditorView: View {
    @State private var selectedImage: UIImage?
    @State private var showPicker = false
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if let img = selectedImage, let editor = FullEditorView(uiImage: img) {
                editor
            } else {
                ZStack {
                    Color.black.ignoresSafeArea()
                    VStack(spacing: 20) {
                        Image(systemName: "slider.horizontal.3").font(.system(size: 56)).foregroundColor(.white.opacity(0.4))
                        Text("Select a photo to edit").font(.title3).foregroundColor(.white)
                        Text("Curves • HSL • Healing • Clone • Export").font(.body).foregroundColor(.white.opacity(0.5))
                        Button { showPicker = true } label: {
                            Label("Choose Photo", systemImage: "photo.on.rectangle").font(.headline).foregroundColor(.white)
                                .padding(.horizontal, 24).padding(.vertical, 12)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.orange))
                        }
                    }
                }
                .sheet(isPresented: $showPicker) { PhotoPickerView(selectedImage: $selectedImage) }
            }
        }
    }
}

struct PhotoPickerView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var cfg = PHPickerConfiguration(); cfg.selectionLimit = 1; cfg.filter = .images
        let picker = PHPickerViewController(configuration: cfg)
        picker.delegate = context.coordinator; return picker
    }
    func updateUIViewController(_ ui: PHPickerViewController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPickerView
        init(_ p: PhotoPickerView) { parent = p }
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let r = results.first else { parent.dismiss(); return }
            r.itemProvider.loadObject(ofClass: UIImage.self) { img, _ in
                DispatchQueue.main.async { self.parent.selectedImage = img as? UIImage; self.parent.dismiss() }
            }
        }
    }
}

// MARK: - Settings
struct SettingsView: View {
    @EnvironmentObject var settings: SettingsManager
    @State private var showReset = false; @State private var showAbout = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack { Label("Format", systemImage:"photo"); Spacer(); Picker("",selection:$settings.captureFormat){ForEach(CaptureFormat.allCases,id:\.self){Text($0.rawValue).tag($0)}}.pickerStyle(.menu) }
                    HStack {
                        Label("Format", systemImage:"photo")
                        Spacer()
                        Picker("",selection:$settings.captureFormat){
                            ForEach(CaptureFormat.allCases,id:\.self){Text($0.rawValue).tag($0)}
                        }.pickerStyle(.menu)
                    }
                } header: { Label("Capture", systemImage:"camera.aperture") }
                Section {
                    Toggle("Grid Overlay", isOn:$settings.enableGrid).tint(.orange)
                    Toggle("Live Histogram", isOn:$settings.enableHistogram).tint(.orange)
                    Toggle("Focus Peaking", isOn:$settings.enableFocusPeaking).tint(.orange)
                    Toggle("Zebra Exposure", isOn:$settings.enableZebraExposure).tint(.orange)
                    Toggle("Level Indicator", isOn:$settings.enableLevelIndicator).tint(.orange)
                } header: { Label("Display", systemImage:"rectangle.3.group") }
                Section {
                    Toggle("AI Assistant", isOn:$settings.enableAIAssistant).tint(.orange)
                    Toggle("Auto Enhancement", isOn:$settings.enableAutoEnhancement).tint(.orange)
                } header: { Label("AI", systemImage:"brain.head.profile") } footer: { Text("All AI runs on-device. Nothing leaves your phone.") }
                Section {
                    Picker("Language", selection:$settings.preferredLanguage){ForEach(SupportedLanguage.allCases,id:\.self){Text($0.rawValue).tag($0)}}
                    Picker("Theme", selection:$settings.colorTheme){ForEach(ColorTheme.allCases,id:\.self){Label($0.rawValue,systemImage:$0.systemName).tag($0)}}
                    Toggle("Haptic Feedback", isOn:$settings.hapticFeedbackEnabled).tint(.orange)
                } header: { Label("Appearance", systemImage:"paintbrush.fill") }
                Section {
                    Button { showAbout = true } label: { Label("About NovaCam", systemImage:"info.circle") }
                    Button(role:.destructive){ showReset = true } label: { Label("Reset All Settings", systemImage:"trash") }
                }
            }
            .navigationTitle("Settings")
            .alert("Reset?", isPresented:$showReset){Button("Cancel",role:.cancel){};Button("Reset",role:.destructive){settings.resetAll()}} message:{Text("Restore all defaults.")}
            .sheet(isPresented:$showAbout){ AboutView() }
        }
    }
}

struct AboutView: View {
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack {
            VStack(spacing:20) {
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius:28).fill(LinearGradient(colors:[Color.orange,Color.orange.opacity(0.7)],startPoint:.topLeading,endPoint:.bottomTrailing)).frame(width:100,height:100)
                    Image(systemName:"camera.fill").font(.system(size:44)).foregroundColor(.white)
                }
                Text("NovaCam AI").font(.largeTitle).fontWeight(.bold)
                Text("Version 1.0.0").font(.subheadline).foregroundColor(.secondary)
                Text("The Ultimate Free Professional Camera").font(.callout).foregroundColor(.secondary)
                Divider().padding(.horizontal,40)
                VStack(alignment:.leading,spacing:8) {
                    AboutRow(icon:"lock.shield.fill",text:"100% Offline — No Cloud")
                    AboutRow(icon:"eye.slash.fill",text:"No Tracking, No Analytics, No Ads")
                    AboutRow(icon:"creditcard.fill",text:"Free Forever — No Subscriptions")
                    AboutRow(icon:"cpu.fill",text:"On-Device AI")
                }.padding(.horizontal,32)
                Spacer()
                Text("© 2026 NovaCam").font(.caption).foregroundColor(.secondary)
            }.padding().toolbar{ToolbarItem(placement:.confirmationAction){Button("Done"){dismiss()}}}
        }
    }
}
struct AboutRow: View { let icon: String; let text: String; var body: some View { HStack(spacing:12){Image(systemName:icon).foregroundColor(.orange).frame(width:24);Text(text).font(.subheadline);Spacer()} } }
