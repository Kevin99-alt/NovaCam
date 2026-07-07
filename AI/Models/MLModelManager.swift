import Foundation
import CoreML
import Vision

@MainActor
final class MLModelManager: ObservableObject {
    static let shared = MLModelManager()

    @Published var sceneClassifier: VNCoreMLModel?
    @Published var objectDetector: VNCoreMLModel?
    @Published var faceLandmarker: VNCoreMLModel?
    @Published var foodClassifier: VNCoreMLModel?
    @Published var qualityPredictor: VNCoreMLModel?
    @Published var noiseEstimator: VNCoreMLModel?
    @Published var isLoading = false
    @Published var loadProgress: Double = 0
    @Published var isReady = false

    private let queue = DispatchQueue(label: "com.novacam.ml", qos: .userInitiated)

    func loadAllModels() async {
        isLoading = true; loadProgress = 0
        let names = ["SceneClassifier","ObjectDetector","FaceLandmarker","FoodClassifier","QualityPredictor","NoiseEstimator"]
        let kps: [WritableKeyPath<MLModelManager, VNCoreMLModel?>] = [
            \.sceneClassifier, \.objectDetector, \.faceLandmarker,
            \.foodClassifier, \.qualityPredictor, \.noiseEstimator
        ]
        for (i, name) in names.enumerated() {
            let kp = kps[i]
            if let m = try? await loadModel(named: name) {
                switch i {
                case 0: sceneClassifier = m
                case 1: objectDetector = m
                case 2: faceLandmarker = m
                case 3: foodClassifier = m
                case 4: qualityPredictor = m
                case 5: noiseEstimator = m
                default: break
                }
            }
            loadProgress = Double(i+1)/Double(names.count)
        }
        isLoading = false; isReady = true
    }

    func loadModel(named: String) async throws -> VNCoreMLModel {
        try await withCheckedThrowingContinuation { c in
            queue.async {
                guard let url = Bundle.main.url(forResource: named, withExtension: "mlmodelc") else {
                    c.resume(throwing: MLModelError.notFound(named)); return
                }
                do {
                    let compiled = try MLModel.compileModel(at: url)
                    let mlModel = try MLModel(contentsOf: compiled)
                    c.resume(returning: try VNCoreMLModel(for: mlModel))
                } catch { c.resume(throwing: error) }
            }
        }
    }
}

enum MLModelError: LocalizedError {
    case notFound(String)
    var errorDescription: String? { if case .notFound(let n) = self { return "Model '\(n)' not found" }; return nil }
}
