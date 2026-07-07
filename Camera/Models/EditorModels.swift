import Foundation
import CoreGraphics
import SwiftUI

// MARK: - Editor State
struct EditorState: Equatable {
    var cropRect: CGRect = .zero; var rotation: Double = 0; var flipHorizontal = false; var flipVertical = false
    var perspectiveCorrection = PerspectiveCorrection.zero; var straightenAngle: Double = 0
    var exposure: Double = 0; var contrast: Double = 0; var brightness: Double = 0
    var highlights: Double = 0; var shadows: Double = 0; var whites: Double = 0; var blacks: Double = 0
    var temperature: Double = 0; var tint: Double = 0; var saturation: Double = 0; var vibrance: Double = 0
    var rgbCurve = ToneCurve.linear; var redCurve = ToneCurve.linear
    var greenCurve = ToneCurve.linear; var blueCurve = ToneCurve.linear
    var hslAdjustments: [HSLAdjustment] = HSLHue.allCases.map { HSLAdjustment(hue: $0) }
    var sharpening: Double = 0; var noiseReduction: Double = 0; var clarity: Double = 0
    var texture: Double = 0; var dehaze: Double = 0; var vignette: Double = 0
    var grain: Double = 0; var grainSize: Double = 25; var grainRoughness: Double = 50
    var healingSpots: [HealingSpot] = []; var cloneSources: [CloneSource] = []
    var undoStack: [EditorSnapshot] = []; var redoStack: [EditorSnapshot] = []
    static let `default` = EditorState()
}

// MARK: - Tone Curve
struct ToneCurve: Equatable {
    var controlPoints: [CGPoint]
    static let linear = ToneCurve(controlPoints: [CGPoint(x:0,y:0), CGPoint(x:1,y:1)])
    static let mediumContrast = ToneCurve(controlPoints: [
        CGPoint(x:0,y:0), CGPoint(x:0.25,y:0.15), CGPoint(x:0.5,y:0.5), CGPoint(x:0.75,y:0.85), CGPoint(x:1,y:1)])
    static let strongContrast = ToneCurve(controlPoints: [
        CGPoint(x:0,y:0), CGPoint(x:0.2,y:0.05), CGPoint(x:0.5,y:0.5), CGPoint(x:0.8,y:0.95), CGPoint(x:1,y:1)])
    static let fade = ToneCurve(controlPoints: [
        CGPoint(x:0,y:0.05), CGPoint(x:0.25,y:0.2), CGPoint(x:0.5,y:0.5), CGPoint(x:0.75,y:0.8), CGPoint(x:1,y:0.95)])
    func evaluate(at x: Double) -> Double {
        let cx = max(0, min(1, x))
        for i in 0..<(controlPoints.count-1) {
            let (p0,p1) = (controlPoints[i], controlPoints[i+1])
            if cx >= Double(p0.x) && cx <= Double(p1.x) {
                let t = (cx - Double(p0.x)) / (Double(p1.x) - Double(p0.x))
                return Double(p0.y) + t * (Double(p1.y) - Double(p0.y))
            }
        }
        return x
    }
}

// MARK: - HSL Adjustment
struct HSLAdjustment: Equatable, Identifiable {
    let id = UUID(); let hue: HSLHue
    var hueShift: Double = 0; var saturation: Double = 0; var luminance: Double = 0
}

enum HSLHue: String, CaseIterable, Identifiable {
    case red, orange, yellow, green, cyan, blue, magenta, purple
    var id: String { rawValue }
    var color: Color {
        switch self {
        case .red: .red; case .orange: .orange; case .yellow: .yellow
        case .green: .green; case .cyan: .cyan; case .blue: .blue
        case .magenta: .pink; case .purple: .purple
        }
    }
    var centerAngle: Double {
        switch self {
        case .red: 0; case .orange: 30; case .yellow: 60; case .green: 120
        case .cyan: 180; case .blue: 240; case .magenta: 300; case .purple: 270
        }
    }
}

// MARK: - Healing & Clone
struct HealingSpot: Equatable, Identifiable {
    let id = UUID(); let position: CGPoint; let radius: CGFloat
    let opacity: Float; let feather: CGFloat; let timestamp: Date
}
struct CloneSource: Equatable, Identifiable {
    let id = UUID(); let sourcePosition: CGPoint; let targetPosition: CGPoint
    let radius: CGFloat; let opacity: Float; let timestamp: Date
}
struct PerspectiveCorrection: Equatable {
    var topLeft = CGPoint(x:0,y:0); var topRight = CGPoint(x:1,y:0)
    var bottomLeft = CGPoint(x:0,y:1); var bottomRight = CGPoint(x:1,y:1)
    static let zero = PerspectiveCorrection()
}
struct EditorSnapshot: Equatable, Codable {
    let timestamp: Date; let label: String
}

// MARK: - Editor Tool
enum EditorTool: String, CaseIterable, Identifiable {
    case crop, rotate, perspective, exposure, contrast, highlights, shadows
    case temperature, saturation, vibrance, curves, hsl
    case sharpen, noiseReduction, clarity, dehaze, vignette, grain, healing, clone
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .crop: "crop"; case .rotate: "rotate.right"; case .perspective: "perspective"
        case .exposure: "sun.max"; case .contrast: "circle.lefthalf.filled"
        case .highlights: "sun.max.fill"; case .shadows: "moon.fill"
        case .temperature: "thermometer.medium"; case .saturation: "paintpalette"
        case .vibrance: "circle.hexagongrid"; case .curves: "chart.line.uptrend.xyaxis"
        case .hsl: "circle.hexagonpath"; case .sharpen: "triangle"
        case .noiseReduction: "circle.dotted"; case .clarity: "circle.lefthalf.striped.horizontal"
        case .dehaze: "sun.haze"; case .vignette: "circle.dashed.inset.filled"
        case .grain: "circle.grid.cross"; case .healing: "bandage"
        case .clone: "circle.dotted.and.circle"
        }
    }
    var category: EditorToolCategory {
        switch self {
        case .crop, .rotate, .perspective: .transform
        case .exposure, .contrast, .highlights, .shadows: .light
        case .temperature, .saturation, .vibrance, .curves, .hsl: .color
        case .sharpen, .noiseReduction, .clarity, .dehaze: .detail
        case .vignette, .grain: .effects
        case .healing, .clone: .retouch
        }
    }
}

enum EditorToolCategory: String, CaseIterable, Identifiable {
    case transform, light, color, detail, effects, retouch
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .transform: "crop.rotate"; case .light: "sun.max"; case .color: "paintpalette"
        case .detail: "triangle"; case .effects: "circle.dashed.inset.filled"; case .retouch: "bandage"
        }
    }
}

enum CurveChannel: String, CaseIterable {
    case rgb, red, green, blue
    var color: Color {
        switch self {
        case .rgb: .white; case .red: .red; case .green: .green; case .blue: .blue
        }
    }
}
