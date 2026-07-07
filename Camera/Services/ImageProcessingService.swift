import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

final class ImageProcessingService: ImageProcessingServiceProtocol {
    private let context: CIContext

    init() {
        if let device = MTLCreateSystemDefaultDevice() {
            context = CIContext(mtlDevice: device, options: [
                .workingColorSpace: CGColorSpace(name: CGColorSpace.displayP3)!,
                .highQualityDownsample: true
            ])
        } else {
            context = CIContext(options: [.highQualityDownsample: true])
        }
    }

    func processPhoto(_ photo: CapturedPhoto, with enhancements: EnhancementPreset) async throws -> ProcessedPhoto {
        guard var image = CIImage(data: photo.processedData) else { throw ImgErr.invalid }
        if enhancements.noiseReduction > 0 {
            let f = CIFilter.noiseReduction()
            f.inputImage = image; f.noiseLevel = enhancements.noiseReduction * 0.1
            image = f.outputImage ?? image
        }
        if enhancements.sharpening > 0 {
            let f = CIFilter.sharpenLuminance()
            f.inputImage = image; f.sharpness = enhancements.sharpening
            image = f.outputImage ?? image
        }
        if enhancements.shadowRecovery > 0 {
            let f = CIFilter.highlightShadowAdjust()
            f.inputImage = image; f.shadowAmount = enhancements.shadowRecovery
            image = f.outputImage ?? image
        }
        guard let cg = context.createCGImage(image, from: image.extent) else { throw ImgErr.render }
        let cs = CGColorSpace(name: CGColorSpace.displayP3)!
        let imageData = context.heifRepresentation(of: image, format: .RGBA8, colorSpace: cs,
            options: [.init(rawValue: kCGImageDestinationLossyCompressionQuality as String): 0.92]) ?? Data()
        let thumb = UIImage(cgImage: cg).jpegData(compressionQuality: 0.8) ?? Data()
        let score = PhotoQualityScore(
            overallScore: 80, sharpnessScore: 80, exposureScore: 82,
            compositionScore: 75, noiseScore: 85, colorScore: 78,
            dynamicRangeEstimate: 8, blurPercentage: 0.05,
            overexposedPercentage: 0.02, underexposedPercentage: 0.03,
            noiseLevel: .low, whiteBalanceAccuracy: 0.9,
            exposureAssessment: .perfect, focusAssessment: .good,
            compositionAssessment: .good, suggestions: []
        )
        return ProcessedPhoto(imageData: imageData, previewData: thumb,
                              metadata: photo.metadata, qualityScore: score,
                              appliedEnhancements: [])
    }

    enum ImgErr: LocalizedError {
        case invalid, render
        var errorDescription: String? {
            switch self {
            case .invalid: return "Invalid image"
            case .render: return "Render failed"
            }
        }
    }
}
