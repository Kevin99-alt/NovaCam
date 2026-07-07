import Foundation; import CoreGraphics
enum AppConstants {
    static let appName="NovaCam AI"; static let appVersion="1.0.0"; static let buildNumber="1"
    static let minimumOSVersion="18.0"; static let bundleIdentifier="com.novacam.ios"
    static let cameraLaunchTimeout:TimeInterval=0.3; static let captureDelayTarget:TimeInterval=0.05
    static let imageProcessingTimeout:TimeInterval=1.0; static let maxZoomFactor:CGFloat=10.0
    static let histogramBins=256; static let sceneAnalysisInterval:TimeInterval=0.5
    static let enableRAWCapture=true; static let enableHDRCapture=true; static let enableNightMode=true
    static let enablePortraitMode=true; static let enableMacroMode=true; static let enableDocumentScanning=true
    static let enableVideoRecording=true; static let enableAIAnalysis=true
}
