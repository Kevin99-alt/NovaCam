import Foundation
import CoreImage
import SwiftUI

// MARK: - Editor ViewModel
@MainActor
final class EditorViewModel: ObservableObject {
    @Published var editorState = EditorState.default
    @Published var selectedTool: EditorTool = .exposure
    @Published var selectedCategory: EditorToolCategory = .light
    @Published var isProcessing = false; @Published var previewImage: UIImage?
    @Published var canUndo = false; @Published var canRedo = false
    @Published var showBeforeAfter = false

    private let originalImage: CIImage
    private let context: CIContext
    private var previewWorkItem: DispatchWorkItem?
    private let queue = DispatchQueue(label: "com.novacam.editor", qos: .userInteractive)

    // Slider bindings
    var exposureB: Binding<Double> { b(\.exposure) }; var contrastB: Binding<Double> { b(\.contrast) }
    var brightnessB: Binding<Double> { b(\.brightness) }; var highlightsB: Binding<Double> { b(\.highlights) }
    var shadowsB: Binding<Double> { b(\.shadows) }; var temperatureB: Binding<Double> { b(\.temperature) }
    var tintB: Binding<Double> { b(\.tint) }; var saturationB: Binding<Double> { b(\.saturation) }
    var vibranceB: Binding<Double> { b(\.vibrance) }; var sharpeningB: Binding<Double> { b(\.sharpening) }
    var noiseB: Binding<Double> { b(\.noiseReduction) }; var clarityB: Binding<Double> { b(\.clarity) }
    var dehazeB: Binding<Double> { b(\.dehaze) }; var vignetteB: Binding<Double> { b(\.vignette) }
    var grainB: Binding<Double> { b(\.grain) }
    private func b(_ kp: WritableKeyPath<EditorState, Double>) -> Binding<Double> {
        Binding(get: { self.editorState[keyPath: kp] },
                set: { self.editorState[keyPath: kp] = $0; self.requestPreview() })
    }

    init(ciImage: CIImage) {
        self.originalImage = ciImage
        if let dev = MTLCreateSystemDefaultDevice() {
            context = CIContext(mtlDevice: dev, options: [.workingColorSpace: CGColorSpace(name: CGColorSpace.displayP3)!,
                                                            .highQualityDownsample: true])
        } else { context = CIContext(options: [.highQualityDownsample: true]) }
        generatePreview()
    }

    func selectTool(_ tool: EditorTool) { selectedTool = tool; selectedCategory = tool.category }
    func selectCategory(_ cat: EditorToolCategory) {
        selectedCategory = cat
        if let t = EditorTool.allCases.first(where: { $0.category == cat }) { selectedTool = t }
    }

    // MARK: - Curves
    func updateCurve(channel: CurveChannel, points: [CGPoint]) {
        let c = ToneCurve(controlPoints: points)
        switch channel {
        case .rgb: editorState.rgbCurve = c; case .red: editorState.redCurve = c
        case .green: editorState.greenCurve = c; case .blue: editorState.blueCurve = c
        }; requestPreview()
    }
    func addCurvePoint(channel: CurveChannel, at point: CGPoint) {
        var c = getCurve(channel); c.controlPoints.append(point)
        c.controlPoints.sort { $0.x < $1.x }; updateCurve(channel: channel, points: c.controlPoints)
    }
    func removeCurvePoint(channel: CurveChannel, at idx: Int) {
        var c = getCurve(channel)
        guard idx >= 1, idx < c.controlPoints.count - 1 else { return }
        c.controlPoints.remove(at: idx); updateCurve(channel: channel, points: c.controlPoints)
    }
    func getCurve(_ ch: CurveChannel) -> ToneCurve {
        switch ch {
        case .rgb: editorState.rgbCurve; case .red: editorState.redCurve
        case .green: editorState.greenCurve; case .blue: editorState.blueCurve
        }
    }

    // MARK: - HSL
    func updateHSL(hue: HSLHue, hs: Double?, sat: Double?, lum: Double?) {
        guard let i = editorState.hslAdjustments.firstIndex(where: { $0.hue == hue }) else { return }
        if let v = hs { editorState.hslAdjustments[i].hueShift = v }
        if let v = sat { editorState.hslAdjustments[i].saturation = v }
        if let v = lum { editorState.hslAdjustments[i].luminance = v }
        requestPreview()
    }
    func resetHSL(_ hue: HSLHue) {
        guard let i = editorState.hslAdjustments.firstIndex(where: { $0.hue == hue }) else { return }
        editorState.hslAdjustments[i].hueShift = 0; editorState.hslAdjustments[i].saturation = 0
        editorState.hslAdjustments[i].luminance = 0; requestPreview()
    }
    func resetAllHSL() { for i in editorState.hslAdjustments.indices { editorState.hslAdjustments[i] = HSLAdjustment(hue: editorState.hslAdjustments[i].hue) }; requestPreview() }

    // MARK: - Healing / Clone
    func addHealingSpot(at point: CGPoint, radius: CGFloat = 0.05) {
        editorState.healingSpots.append(HealingSpot(position: point, radius: radius, opacity: 1, feather: 0.5, timestamp: Date()))
        requestPreview()
    }
    func removeLastHealing() { if !editorState.healingSpots.isEmpty { editorState.healingSpots.removeLast(); requestPreview() } }
    func paintClone(from src: CGPoint, to tgt: CGPoint, radius: CGFloat = 0.05) {
        editorState.cloneSources.append(CloneSource(sourcePosition: src, targetPosition: tgt, radius: radius, opacity: 1, timestamp: Date()))
        requestPreview()
    }

    // MARK: - Undo/Redo
    func undo() {
        guard !editorState.undoStack.isEmpty else { return }
        editorState.redoStack.append(EditorSnapshot(timestamp: Date(), label: "current"))
        editorState.undoStack.removeLast(); updateUR(); generatePreview()
    }
    func redo() {
        guard !editorState.redoStack.isEmpty else { return }
        editorState.undoStack.append(editorState.redoStack.removeLast()); updateUR(); generatePreview()
    }
    func pushUndo(_ label: String) {
        editorState.undoStack.append(EditorSnapshot(timestamp: Date(), label: label))
        editorState.redoStack.removeAll(); updateUR()
    }
    private func updateUR() { canUndo = !editorState.undoStack.isEmpty; canRedo = !editorState.redoStack.isEmpty }

    // MARK: - Reset
    func resetTool(_ tool: EditorTool) {
        switch tool {
        case .exposure: editorState.exposure = 0; case .contrast: editorState.contrast = 0
        case .highlights: editorState.highlights = 0; case .shadows: editorState.shadows = 0
        case .temperature: editorState.temperature = 0
        case .saturation: editorState.saturation = 0; case .vibrance: editorState.vibrance = 0
        case .curves: editorState.rgbCurve = .linear; editorState.redCurve = .linear
            editorState.greenCurve = .linear; editorState.blueCurve = .linear
        case .hsl: resetAllHSL()
        case .sharpen: editorState.sharpening = 0; case .noiseReduction: editorState.noiseReduction = 0
        case .clarity: editorState.clarity = 0; case .dehaze: editorState.dehaze = 0
        case .vignette: editorState.vignette = 0; case .grain: editorState.grain = 0
        case .healing: editorState.healingSpots.removeAll()
        case .clone: editorState.cloneSources.removeAll()
        default: break
        }; generatePreview()
    }
    func resetAll() { editorState = EditorState.default; editorState.undoStack.removeAll(); editorState.redoStack.removeAll(); updateUR(); generatePreview() }

    // MARK: - Preview Pipeline
    private func requestPreview() {
        previewWorkItem?.cancel()
        let w = DispatchWorkItem { [weak self] in Task { @MainActor in self?.generatePreview() } }
        previewWorkItem = w; queue.asyncAfter(deadline: .now() + 0.05, execute: w)
    }

    func generatePreview() {
        isProcessing = true
        var out = originalImage
        // Light
        if editorState.exposure != 0 { let f = CIFilter.exposureAdjust(); f.inputImage = out; f.ev = Float(editorState.exposure); out = f.outputImage ?? out }
        if editorState.contrast != 0 || editorState.brightness != 0 { let f = CIFilter.colorControls(); f.inputImage = out; f.contrast = Float(1+editorState.contrast); f.brightness = Float(editorState.brightness); out = f.outputImage ?? out }
        if editorState.highlights != 0 || editorState.shadows != 0 { let f = CIFilter.highlightShadowAdjust(); f.inputImage = out; f.highlightAmount = Float(1-max(0,editorState.highlights)); f.shadowAmount = Float(1+max(0,editorState.shadows)); out = f.outputImage ?? out }
        // Color
        if editorState.temperature != 0 { let f = CIFilter.temperatureAndTint(); f.inputImage = out; f.neutral = CIVector(x: CGFloat(6500+editorState.temperature*4000), y: CGFloat(editorState.tint*150)); out = f.outputImage ?? out }
        if editorState.saturation != 0 { let f = CIFilter.colorControls(); f.inputImage = out; f.saturation = Float(1+editorState.saturation); out = f.outputImage ?? out }
        if editorState.vibrance != 0 { let f = CIFilter.vibrance(); f.inputImage = out; f.amount = Float(editorState.vibrance); out = f.outputImage ?? out }
        // Curves
        if editorState.rgbCurve != .linear { out = applyToneCurve(out, editorState.rgbCurve) }
        // Detail
        if editorState.sharpening > 0 { let f = CIFilter.sharpenLuminance(); f.inputImage = out; f.sharpness = Float(editorState.sharpening); out = f.outputImage ?? out }
        if editorState.noiseReduction > 0 { let f = CIFilter.noiseReduction(); f.inputImage = out; f.noiseLevel = Float(editorState.noiseReduction * 0.1); out = f.outputImage ?? out }
        if editorState.dehaze > 0 { let f = CIFilter.highlightShadowAdjust(); f.inputImage = out; f.highlightAmount = Float(1-editorState.dehaze*0.5); out = f.outputImage ?? out }
        // Effects
        if editorState.vignette != 0 { let f = CIFilter.vignette(); f.inputImage = out; f.intensity = Float(editorState.vignette); f.radius = Float(out.extent.width)*0.8; out = f.outputImage ?? out }
        // Render
        if let cg = context.createCGImage(out, from: out.extent) { previewImage = UIImage(cgImage: cg) }
        isProcessing = false
    }

    private func applyToneCurve(_ image: CIImage, _ curve: ToneCurve) -> CIImage {
        let f = CIFilter.toneCurve(); f.inputImage = image
        let pts = curve.controlPoints
        f.point0 = CGPoint(x: Double(pts[0].x), y: 1-Double(pts[0].y))
        if pts.count > 2 { f.point1 = CGPoint(x: Double(pts[1].x), y: 1-Double(pts[1].y)) }
        if pts.count > 3 { f.point2 = CGPoint(x: Double(pts[2].x), y: 1-Double(pts[2].y)) }
        if pts.count > 4 { f.point3 = CGPoint(x: Double(pts[3].x), y: 1-Double(pts[3].y)) }
        return f.outputImage ?? image
    }

    // MARK: - Export
    func exportHEIF(quality: Float = 0.92) -> Data? {
        guard let cg = previewImage?.cgImage else { return nil }
        return context.heifRepresentation(of: CIImage(cgImage: cg), format: .RGBA8,
                                           colorSpace: CGColorSpace(name: CGColorSpace.displayP3)!,
                                           options: [.init(rawValue: kCGImageDestinationLossyCompressionQuality as String): quality])
    }
    func exportJPEG(quality: Float = 0.92) -> Data? { previewImage?.jpegData(compressionQuality: CGFloat(quality)) }
}
