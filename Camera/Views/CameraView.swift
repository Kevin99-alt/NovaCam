import SwiftUI
import AVFoundation

// MARK: - Camera View (Updated with real preview + gestures)
struct CameraView: View {
    @StateObject private var viewModel = CameraViewModel(
        cameraService: CameraService(),
        aiService: SceneAnalysisService(),
        imageProcessor: ImageProcessingService()
    )
    @EnvironmentObject private var settingsManager: SettingsManager
    @EnvironmentObject private var appState: AppState
    @State private var showModeSelector = false
    @State private var showQualityOverlay = false

    var body: some View {
        ZStack {
            CameraPreviewView(
                session: (viewModel.cameraService as? CameraService)?.session,
                onTapToFocus: { viewModel.setFocus(at: $0) },
                onPinchToZoom: { viewModel.setZoom(viewModel.currentZoom * $0) },
                onDoubleTap: { viewModel.toggleFocusLock() },
                onLongPress: { _ in viewModel.toggleExposureLock() }
            )
            .ignoresSafeArea()

            cameraOverlays
            topBar
            if !viewModel.suggestions.isEmpty { aiSuggestionsBar }
            VStack { Spacer(); bottomControls }
            if showModeSelector { modeSelectorOverlay }
            if showQualityOverlay, let score = viewModel.currentQualityScore { qualityScoreOverlay(score) }
        }
        .background(Color.black)
        .task { await viewModel.setupAndStart() }
        .onDisappear { viewModel.stopCamera() }
    }

    @ViewBuilder private var cameraOverlays: some View {
        Group {
            if viewModel.showGrid { GridOverlayView(type: viewModel.gridType) }
            if viewModel.showLevel { LevelIndicatorView(angle: viewModel.horizonAngle) }
            if viewModel.showHistogram {
                HistogramView(red: viewModel.redHistogram, green: viewModel.greenHistogram,
                              blue: viewModel.blueHistogram, luminance: viewModel.luminanceHistogram)
                    .frame(width: 120, height: 70).position(x: UIScreen.main.bounds.width - 75, y: 120)
            }
        }
    }

    private var topBar: some View {
        VStack {
            HStack {
                Button(action: cycleFlash) {
                    Image(systemName: flashIcon).font(.system(size:18)).foregroundColor(.white)
                        .frame(width:40,height:40).background(Circle().fill(.ultraThinMaterial))
                }
                Spacer()
                if viewModel.detectedScene != .unknown {
                    HStack(spacing:6) {
                        Image(systemName: viewModel.detectedScene.icon).font(.system(size:14))
                        Text(viewModel.detectedScene.rawValue).font(.system(size:12,weight:.medium))
                    }.foregroundColor(.white).padding(.horizontal,12).padding(.vertical,6).background(Capsule().fill(.ultraThinMaterial))
                }
                Spacer()
                Menu {
                    Toggle("Grid", isOn:$viewModel.showGrid); Toggle("Histogram", isOn:$viewModel.showHistogram)
                    Toggle("Level", isOn:$viewModel.showLevel)
                    Picker("Grid", selection:$viewModel.gridType){ForEach(GridType.allCases,id:\.self){Text($0.rawValue).tag($0)}}
                } label: {
                    Image(systemName:"ellipsis.circle.fill").font(.system(size:22)).foregroundColor(.white)
                        .frame(width:40,height:40).background(Circle().fill(.ultraThinMaterial))
                }
            }.padding(.horizontal,20).padding(.top,54)
            Spacer()
        }
    }

    private var aiSuggestionsBar: some View {
        VStack {
            Spacer()
            ScrollView(.horizontal,showsIndicators:false) {
                HStack(spacing:8) {
                    ForEach(Array(viewModel.suggestions.prefix(3))) { s in
                        HStack(spacing:6) {
                            Image(systemName:s.icon).font(.system(size:12)); Text(s.message).font(.system(size:12))
                        }.foregroundColor(.white).padding(.horizontal,12).padding(.vertical,8)
                        .background(Capsule().fill(s.severity == .warning ? Color.orange.opacity(0.8) : Color.white.opacity(0.15)))
                    }
                }.padding(.horizontal,20).padding(.bottom,160)
            }
        }
    }

    private var bottomControls: some View {
        VStack(spacing:0) {
            if viewModel.isManualMode { manualQuickControls }
            HStack(alignment:.bottom) {
                Button { appState.selectedTab = .gallery } label: {
                    RoundedRectangle(cornerRadius:8).fill(Color.white.opacity(0.15)).frame(width:50,height:50)
                        .overlay(Image(systemName:"photo.on.rectangle").foregroundColor(.white.opacity(0.5)))
                }
                Spacer()
                Button {
                    Task {
                        await viewModel.capturePhoto()
                        withAnimation(.spring(response:0.3)){showQualityOverlay=true}
                        try? await Task.sleep(nanoseconds:3_000_000_000)
                        withAnimation{showQualityOverlay=false}
                    }
                } label: {
                    ZStack {
                        Circle().stroke(Color.white,lineWidth:5).frame(width:76,height:76)
                        Circle().fill(Color.white).frame(width:62,height:62)
                        if viewModel.isCapturing { ProgressView().tint(.black) }
                    }
                }.disabled(viewModel.isCapturing)
                Spacer()
                Button { withAnimation(.spring(response:0.3)){showModeSelector.toggle()} } label: {
                    VStack(spacing:2){Image(systemName:viewModel.selectedMode.icon).font(.system(size:22));Text(viewModel.selectedMode.rawValue).font(.system(size:10))}.foregroundColor(.white).frame(width:50,height:50)
                }
            }.padding(.horizontal,24).padding(.bottom,36)
        }
    }

    private var manualQuickControls: some View {
        HStack(spacing:20) {
            ManualControlBadge(icon:"camera.aperture",value:String(format:"%.0f",viewModel.displayISO),label:"ISO")
            ManualControlBadge(icon:"clock",value:viewModel.displayShutterSpeed,label:"Speed")
            ManualControlBadge(icon:"thermometer.sun",value:"Auto",label:"WB")
            ManualControlBadge(icon:"plusminus.circle",value:String(format:"%.1f",viewModel.displayExposureComp),label:"EV")
        }.padding(.vertical,12).background(.ultraThinMaterial)
    }

    private var modeSelectorOverlay: some View {
        VStack { Spacer()
            ScrollView(.horizontal,showsIndicators:false) {
                HStack(spacing:12) {
                    ForEach(CaptureMode.allCases,id:\.self){ mode in
                        Button {
                            withAnimation{viewModel.selectMode(mode);showModeSelector=false}
                        } label: {
                            VStack(spacing:6){Image(systemName:mode.icon).font(.system(size:22));Text(mode.rawValue).font(.system(size:11,weight:.medium))}
                                .foregroundColor(viewModel.selectedMode==mode ? .orange : .white).frame(width:64,height:64)
                                .background(RoundedRectangle(cornerRadius:14).fill(viewModel.selectedMode==mode ? Color.orange.opacity(0.2) : Color.white.opacity(0.1)))
                                .overlay(RoundedRectangle(cornerRadius:14).stroke(viewModel.selectedMode==mode ? Color.orange : Color.clear,lineWidth:1.5))
                        }
                    }
                }.padding(.horizontal,20)
            }.padding(.vertical,16).background(.ultraThinMaterial).padding(.bottom,100)
        }
    }

    private func qualityScoreOverlay(_ score: PhotoQualityScore) -> some View {
        VStack { Spacer()
            VStack(spacing:12) {
                HStack { Text("Quality Score").font(.headline); Spacer(); Text(score.letterGrade).font(.system(size:28,weight:.bold)).foregroundColor(scoreColor(score.overallScore)) }
                HStack(spacing:4){ForEach(0..<10){i in RoundedRectangle(cornerRadius:2).fill(i<score.overallScore/10 ? scoreColor(score.overallScore) : Color.white.opacity(0.2)).frame(height:4)}}
                HStack{ QualityMetricPill(label:"Sharp",value:score.sharpnessScore);QualityMetricPill(label:"Exposure",value:score.exposureScore);QualityMetricPill(label:"Composition",value:score.compositionScore);QualityMetricPill(label:"Noise",value:score.noiseScore);QualityMetricPill(label:"Color",value:score.colorScore)}
            }.padding(20).background(RoundedRectangle(cornerRadius:20).fill(.ultraThinMaterial)).padding(.horizontal,20).padding(.bottom,140)
        }
    }

    private var flashIcon: String {
        switch viewModel.flashMode {
        case .off: "bolt.slash.fill"; case .auto: "bolt.badge.a.fill"
        case .on: "bolt.fill"; case .torch: "flashlight.on.fill"
        }
    }
    private func cycleFlash() {
        let ms: [FlashMode] = [.off,.auto,.on,.torch]
        if let i = ms.firstIndex(of:viewModel.flashMode) { viewModel.flashMode = ms[(i+1)%ms.count]; viewModel.captureSettings.flashMode = viewModel.flashMode }
    }
    private func scoreColor(_ v: Int) -> Color {
        switch v { case 85...: .green; case 70..<85: .yellow; case 50..<70: .orange; default: .red }
    }
}

// Supporting subviews (same as before)
struct ManualControlBadge: View { let icon:String; let value:String; let label:String; var body: some View { VStack(spacing:2){Image(systemName:icon).font(.system(size:14));Text(value).font(.system(size:12,weight:.medium,design:.monospaced));Text(label).font(.system(size:9)).opacity(0.6)}.foregroundColor(.white).frame(minWidth:50) } }
struct QualityMetricPill: View { let label:String; let value:Int; var body: some View { VStack(spacing:2){Text("\(value)").font(.system(size:13,weight:.bold,design:.monospaced));Text(label).font(.system(size:9)).opacity(0.6)}.foregroundColor(.white).frame(maxWidth:.infinity) } }
