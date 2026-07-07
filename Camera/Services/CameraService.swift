import Foundation
import AVFoundation
import UIKit

final class CameraService: NSObject, CameraServiceProtocol {
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var videoInput: AVCaptureDeviceInput?
    private let queue = DispatchQueue(label: "com.novacam.camera", qos: .userInitiated)
    private var videoOutput: AVCaptureMovieFileOutput?
    private var isRecording = false
    private var captureCont: CheckedContinuation<CapturedPhoto, Error>?
    private var videoCont: CheckedContinuation<URL, Error>?

    @Published var isSessionRunning = false
    @Published var isFocusLocked = false
    @Published var isExposureLocked = false
    @Published var currentISO: Float = 0
    var onSessionStarted: (() -> Void)?
    var onSessionStopped: (() -> Void)?
    var onError: ((Error) -> Void)?

    func setupCamera() async throws {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .notDetermined {
            guard await AVCaptureDevice.requestAccess(for: .video) else { throw CamErr.denied }
        } else if status == .denied || status == .restricted {
            throw CamErr.denied
        }
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        if session.canSetSessionPreset(.photo) { session.sessionPreset = .photo }
        guard let dev = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
                ?? AVCaptureDevice.default(for: .video) else { throw CamErr.noDevice }
        let input = try AVCaptureDeviceInput(device: dev)
        guard session.canAddInput(input) else { throw CamErr.config }
        session.addInput(input); videoInput = input
        guard session.canAddOutput(photoOutput) else { throw CamErr.config }
        session.addOutput(photoOutput)
        photoOutput.maxPhotoQualityPrioritization = .quality
    }

    func startSession() async {
        await withCheckedContinuation { c in
            queue.async {
                self.session.startRunning()
                self.isSessionRunning = true
                self.onSessionStarted?()
                c.resume()
            }
        }
    }

    func stopSession() async {
        await withCheckedContinuation { c in
            queue.async {
                self.session.stopRunning()
                self.isSessionRunning = false
                self.onSessionStopped?()
                c.resume()
            }
        }
    }

    func tearDown() {
        session.stopRunning()
        session.inputs.forEach { session.removeInput($0) }
        session.outputs.forEach { session.removeOutput($0) }
    }

    func capturePhoto(with settings: CaptureSettings) async throws -> CapturedPhoto {
        guard isSessionRunning else { throw CamErr.capture }
        return try await withCheckedThrowingContinuation { c in
            self.captureCont = c
            let ps = AVCapturePhotoSettings()
            ps.flashMode = .off
            ps.isHighResolutionPhotoEnabled = true
            self.photoOutput.capturePhoto(with: ps, delegate: self)
        }
    }

    func startVideoRecording(with settings: VideoCaptureSettings) async throws {
        guard isSessionRunning, !isRecording else { throw CamErr.capture }
        let vo = AVCaptureMovieFileOutput()
        guard session.canAddOutput(vo) else { throw CamErr.config }
        session.beginConfiguration(); session.addOutput(vo); session.commitConfiguration()
        videoOutput = vo; isRecording = true
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).mov")
        vo.startRecording(to: url, recordingDelegate: self)
    }

    func stopVideoRecording() async throws -> URL {
        guard let vo = videoOutput, isRecording else { throw CamErr.capture }
        return try await withCheckedThrowingContinuation { c in
            self.videoCont = c
            vo.stopRecording()
        }
    }

    func setFocus(point: CGPoint) {
        guard let d = videoInput?.device else { return }
        try? d.lockForConfiguration()
        if d.isFocusPointOfInterestSupported { d.focusPointOfInterest = point; d.focusMode = .autoFocus }
        d.unlockForConfiguration()
    }

    func setFocusLock(_ locked: Bool) {
        guard let d = videoInput?.device else { return }
        try? d.lockForConfiguration()
        d.focusMode = locked ? .locked : .autoFocus
        d.unlockForConfiguration()
        isFocusLocked = locked
    }

    func setISO(_ value: Float) {
        guard let d = videoInput?.device else { return }
        try? d.lockForConfiguration()
        let clamped = max(d.activeFormat.minISO, min(d.activeFormat.maxISO, value))
        d.setExposureModeCustom(duration: d.exposureDuration, iso: clamped)
        d.unlockForConfiguration()
        currentISO = clamped
    }

    func setExposureCompensation(_ value: Float) {
        guard let d = videoInput?.device else { return }
        try? d.lockForConfiguration()
        d.setExposureTargetBias(max(d.minExposureTargetBias, min(d.maxExposureTargetBias, value)))
        d.unlockForConfiguration()
    }

    func setShutterSpeed(_ duration: CMTime) {
        guard let d = videoInput?.device else { return }
        try? d.lockForConfiguration()
        d.setExposureModeCustom(duration: duration, iso: d.iso)
        d.unlockForConfiguration()
    }

    func setWhiteBalance(temperature: Float, tint: Float) {
        guard let d = videoInput?.device else { return }
        try? d.lockForConfiguration()
        d.setWhiteBalanceModeLocked(with: d.deviceWhiteBalanceGains)
        d.unlockForConfiguration()
    }

    func setExposureLock(_ locked: Bool) {
        guard let d = videoInput?.device else { return }
        try? d.lockForConfiguration()
        d.exposureMode = locked ? .locked : .continuousAutoExposure
        d.unlockForConfiguration()
        isExposureLocked = locked
    }

    func setZoom(_ factor: CGFloat) {
        guard let d = videoInput?.device else { return }
        try? d.lockForConfiguration()
        d.videoZoomFactor = max(1, min(factor, d.activeFormat.videoMaxZoomFactor))
        d.unlockForConfiguration()
    }

    enum CamErr: LocalizedError {
        case unavailable, config, capture, noDevice, denied
        var errorDescription: String? {
            switch self {
            case .unavailable: return "Camera unavailable"
            case .config: return "Configuration failed"
            case .capture: return "Capture failed"
            case .noDevice: return "No video device"
            case .denied: return "Permission denied"
            }
        }
    }
}

extension CameraService: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let e = error { captureCont?.resume(throwing: e); captureCont = nil; return }
        let data = photo.fileDataRepresentation() ?? Data()
        let w = CGFloat(photo.resolvedSettings.photoDimensions.width)
        let h = CGFloat(photo.resolvedSettings.photoDimensions.height)
        let meta = PhotoMetadata(
            captureDate: Date(), iso: 100,
            shutterSpeed: CMTime(value: 1, timescale: 100),
            aperture: 2.8, focalLength: 26,
            whiteBalance: (5500, 0), exposureCompensation: 0,
            flash: false, location: nil, lensModel: nil,
            deviceModel: UIDevice.current.model,
            softwareVersion: "NovaCam 1.0", format: .heif,
            dimensions: CGSize(width: w, height: h),
            orientation: .up
        )
        captureCont?.resume(returning: CapturedPhoto(
            rawData: nil, processedData: data, metadata: meta,
            thumbnailData: nil, pixelBuffer: photo.pixelBuffer
        ))
        captureCont = nil
    }
}

extension CameraService: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo url: URL,
                    from connections: [AVCaptureConnection], error: Error?) {
        isRecording = false
        if let e = error { videoCont?.resume(throwing: e) }
        else { videoCont?.resume(returning: url) }
        videoCont = nil
    }
}
