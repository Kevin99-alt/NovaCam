import Foundation
import CoreMedia
import AVFoundation
import CoreImage

protocol CameraServiceProtocol: AnyObject {
    func setupCamera() async throws
    func startSession() async
    func stopSession() async
    func tearDown()
    func capturePhoto(with: CaptureSettings) async throws -> CapturedPhoto
    func setFocus(point: CGPoint)
    func setFocusLock(_: Bool)
    func setISO(_: Float)
    func setExposureCompensation(_: Float)
    func setShutterSpeed(_: CMTime)
    func setWhiteBalance(temperature: Float, tint: Float)
    func setExposureLock(_: Bool)
    func setZoom(_: CGFloat)
    func startVideoRecording(with: VideoCaptureSettings) async throws
    func stopVideoRecording() async throws -> URL
    var isSessionRunning: Bool { get }
    var session: AVCaptureSession { get }
    var onSessionStarted: (() -> Void)? { get set }
    var onSessionStopped: (() -> Void)? { get set }
    var onError: ((Error) -> Void)? { get set }
}

protocol AIServiceProtocol: AnyObject {
    func analyzeScene(from: CVPixelBuffer) async throws -> SceneAnalysisResult
    func generateSuggestions(from: SceneAnalysisResult, quality: PhotoQualityScore) -> [PhotographySuggestion]
}

protocol ImageProcessingServiceProtocol: AnyObject {
    func processPhoto(_: CapturedPhoto, with: EnhancementPreset) async throws -> ProcessedPhoto
}
