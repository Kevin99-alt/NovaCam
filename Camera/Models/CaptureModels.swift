import Foundation; import CoreMedia
struct CaptureSettings {
    var format: CaptureFormat = .heif; var iso: Float?; var shutterSpeed: CMTime?
    var whiteBalanceTemperature: Float?; var whiteBalanceTint: Float?
    var exposureCompensation: Float = 0; var focusPoint: CGPoint?; var zoomFactor: CGFloat = 1.0
    var isFocusLocked = false; var isExposureLocked = false
    var mode: CaptureMode = .auto; var hdrMode: HDRMode = .auto; var flashMode: FlashMode = .off
    var timerSeconds: Int?; var qualityPreset: QualityPreset = .balanced
    static let `default` = CaptureSettings()
}
struct VideoCaptureSettings {
    var resolution: VideoResolution = .uhd; var frameRate: VideoFrameRate = .fps30
    var codec: VideoCodec = .hevc; var enableStabilization = true
    var iso: Float?; var whiteBalanceTemperature: Float?; var audioEnabled = true
    static let `default` = VideoCaptureSettings()
}
struct CapturedPhoto { let rawData: Data?; let processedData: Data; let metadata: PhotoMetadata; let thumbnailData: Data?; let pixelBuffer: CVPixelBuffer? }
struct ProcessedPhoto { let imageData: Data; let previewData: Data; let metadata: PhotoMetadata; let qualityScore: PhotoQualityScore; let appliedEnhancements: [EnhancementType] }
struct PhotoMetadata { let captureDate: Date; let iso: Float; let shutterSpeed: CMTime; let aperture: Float; let focalLength: Float; let whiteBalance: (temperature: Float, tint: Float); let exposureCompensation: Float; let flash: Bool; let location: PhotoLocation?; let lensModel: String?; let deviceModel: String; let softwareVersion: String; let format: CaptureFormat; let dimensions: CGSize; let orientation: PhotoOrientation }
struct PhotoLocation { let latitude: Double; let longitude: Double; let altitude: Double?; let timestamp: Date }
struct EnhancementPreset {
    var noiseReduction: Float = 0; var sharpening: Float = 0; var shadowRecovery: Float = 0
    var highlightRecovery: Float = 0; var colorEnhancement: Float = 0; var skinToneCorrection = false
    var dynamicRangeOptimization = false; var lensCorrection = true; var perspectiveCorrection = false
    var dehaze: Float = 0; var clarity: Float = 0; var textureEnhancement: Float = 0
    static let none = EnhancementPreset()
    static let auto = EnhancementPreset(noiseReduction:0.3,sharpening:0.2,shadowRecovery:0.3,highlightRecovery:0.3,colorEnhancement:0.15,dynamicRangeOptimization:true,lensCorrection:true)
    static let portrait = EnhancementPreset(noiseReduction:0.4,sharpening:0.1,shadowRecovery:0.2,highlightRecovery:0.3,skinToneCorrection:true,dynamicRangeOptimization:true)
    static let landscape = EnhancementPreset(noiseReduction:0.2,sharpening:0.4,shadowRecovery:0.35,highlightRecovery:0.4,colorEnhancement:0.25,dynamicRangeOptimization:true,dehaze:0.3,clarity:0.3)
    static let night = EnhancementPreset(noiseReduction:0.8,sharpening:0.15,shadowRecovery:0.5,dynamicRangeOptimization:true)
}
enum CaptureFormat: String, CaseIterable { case raw="ProRAW", heif="HEIF", jpeg="JPEG" }
enum CaptureMode: String, CaseIterable { case auto="Auto",manual="Manual",portrait="Portrait",night="Night",hdr="HDR",macro="Macro",document="Document",panorama="Panorama"
    var icon: String { switch self { case .auto:"camera.fill";case .manual:"slider.horizontal.3";case .portrait:"person.crop.artframe";case .night:"moon.stars.fill";case .hdr:"sun.max.trianglebadge.exclamationmark";case .macro:"ant.fill";case .document:"doc.text.fill";case .panorama:"rectangle.portrait.arrowtriangle.2.outward" }}
}
enum HDRMode: String, CaseIterable { case off="Off", auto="Auto", always="Always", smart="Smart HDR" }
enum FlashMode: String, CaseIterable { case off="Off", auto="Auto", on="On", torch="Torch" }
enum QualityPreset: String, CaseIterable { case economy="Economy",balanced="Balanced",quality="Quality",maximum="Maximum" }
enum VideoResolution: String, CaseIterable { case hd="1080p", uhd="4K" }
enum VideoFrameRate: String, CaseIterable { case fps24="24FPS", fps30="30FPS", fps60="60FPS" }
enum VideoCodec: String, CaseIterable { case hevc="HEVC", h264="H.264" }
enum GridType: String, CaseIterable { case ruleOfThirds="Rule of Thirds",goldenRatio="Golden Ratio",crosshair="Crosshair",square="Square",off="Off" }
enum PhotoOrientation: Int { case up=1,down=3,left=6,right=8 }
enum EnhancementType: String, CaseIterable { case noiseReduction,sharpening,shadowRecovery,highlightRecovery,colorEnhancement,skinToneCorrection,dynamicRange,lensCorrection,perspectiveCorrection,dehaze,clarity,texture,vignette,grain }
enum SupportedLanguage: String, CaseIterable { case english,swahili,french,spanish,german,italian,portuguese,arabic,chinese,japanese,korean,russian,hindi,turkish,dutch }
