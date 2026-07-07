import Foundation
import Combine
import CoreMedia
import SwiftUI
import Photos

@MainActor
final class CameraViewModel: ObservableObject {
    let cameraService: CameraServiceProtocol
    private let aiService: AIServiceProtocol
    private let imgProc: ImageProcessingServiceProtocol

    @Published var captureSettings = CaptureSettings.default
    @Published var isSessionRunning = false
    @Published var isCapturing = false
    @Published var lastProcessedPhoto: ProcessedPhoto?
    @Published var currentQualityScore: PhotoQualityScore?
    @Published var detectedScene: SceneClassification = .unknown
    @Published var suggestions: [PhotographySuggestion] = []
    @Published var showGrid = true
    @Published var showHistogram = true
    @Published var showLevel = true
    @Published var gridType: GridType = .ruleOfThirds
    @Published var selectedMode: CaptureMode = .auto
    @Published var errorMessage: String?
    @Published var focusLocked = false
    @Published var exposureLocked = false
    @Published var currentZoom: CGFloat = 1.0
    @Published var flashMode: FlashMode = .off
    @Published var displayISO: Float = 0
    @Published var displayShutterSpeed = "Auto"
    @Published var displayExposureComp: Float = 0
    @Published var horizonAngle: CGFloat = 0
    @Published var redHistogram: [Float] = Array(repeating: 0, count: 256)
    @Published var greenHistogram: [Float] = Array(repeating: 0, count: 256)
    @Published var blueHistogram: [Float] = Array(repeating: 0, count: 256)
    @Published var luminanceHistogram: [Float] = Array(repeating: 0, count: 256)

    private var analysisTimer: Timer?

    init(cameraService: CameraServiceProtocol, aiService: AIServiceProtocol,
         imageProcessor: ImageProcessingServiceProtocol) {
        self.cameraService = cameraService
        self.aiService = aiService
        self.imgProc = imageProcessor
        cameraService.onSessionStarted = { [weak self] in
            Task { @MainActor in self?.isSessionRunning = true }
        }
        cameraService.onSessionStopped = { [weak self] in
            Task { @MainActor in self?.isSessionRunning = false }
        }
        cameraService.onError = { [weak self] e in
            Task { @MainActor in self?.errorMessage = e.localizedDescription }
        }
    }

    func setupAndStart() async {
        do {
            try await cameraService.setupCamera()
            await cameraService.startSession()
            startAnalysisLoop()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func stopCamera() {
        analysisTimer?.invalidate()
        Task { await cameraService.stopSession() }
    }

    func capturePhoto() async {
        guard !isCapturing else { return }
        isCapturing = true
        defer { isCapturing = false }
        do {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            let photo = try await cameraService.capturePhoto(with: captureSettings)
            let processed = try await imgProc.processPhoto(photo, with: detectedScene.suggestedPreset)
            lastProcessedPhoto = processed
            currentQualityScore = processed.qualityScore
        } catch {
            errorMessage = "Capture: \(error.localizedDescription)"
        }
    }

    func setFocus(at point: CGPoint) { cameraService.setFocus(point: point) }
    func toggleFocusLock() { focusLocked.toggle(); cameraService.setFocusLock(focusLocked) }
    func setISO(_ v: Float) { cameraService.setISO(v); captureSettings.iso = v }
    func setExposureCompensation(_ v: Float) { cameraService.setExposureCompensation(v) }
    func toggleExposureLock() { exposureLocked.toggle(); cameraService.setExposureLock(exposureLocked) }
    func setZoom(_ factor: CGFloat) { cameraService.setZoom(factor); currentZoom = factor }
    func selectMode(_ mode: CaptureMode) { selectedMode = mode; captureSettings.mode = mode }
    var isManualMode: Bool { selectedMode == .manual }

    private func startAnalysisLoop() {
        analysisTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                let scene = SceneAnalysisResult(
                    classification: .unknown, subjects: [],
                    lighting: LightingClassification(type: .natural, brightnessLevel: 0.5,
                        colorTemperature: 5500, isBacklit: false, hasMixedLighting: false,
                        lowLightConfidence: 0, suggestedISO: nil),
                    composition: CompositionAnalysis(dominantLines: [], symmetryScore: 0.5,
                        balanceScore: 0.6, ruleOfThirdsAlignment: 0.5, goldenRatioAlignment: 0.4,
                        hasLeadingLines: false, negativeSpacePercentage: 0.3, horizonAngle: 0),
                    timestamp: Date(), confidence: 0
                )
                let qs = self.currentQualityScore ?? PhotoQualityScore(
                    overallScore: 50, sharpnessScore: 50, exposureScore: 50,
                    compositionScore: 50, noiseScore: 50, colorScore: 50,
                    dynamicRangeEstimate: 6, blurPercentage: 0, overexposedPercentage: 0,
                    underexposedPercentage: 0, noiseLevel: .low, whiteBalanceAccuracy: 0.8,
                    exposureAssessment: .perfect, focusAssessment: .good,
                    compositionAssessment: .acceptable, suggestions: []
                )
                self.suggestions = self.aiService.generateSuggestions(from: scene, quality: qs)
            }
        }
    }
}
