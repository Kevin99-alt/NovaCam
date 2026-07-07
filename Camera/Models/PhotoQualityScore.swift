import Foundation
struct PhotoQualityScore: Codable {
    let overallScore: Int; let sharpnessScore: Int; let exposureScore: Int
    let compositionScore: Int; let noiseScore: Int; let colorScore: Int
    let dynamicRangeEstimate: Float; let blurPercentage: Float
    let overexposedPercentage: Float; let underexposedPercentage: Float
    let noiseLevel: NoiseLevel; let whiteBalanceAccuracy: Float
    let exposureAssessment: ExposureAssessment; let focusAssessment: FocusAssessment
    let compositionAssessment: CompositionAssessment; let suggestions: [QualitySuggestion]
    var isExcellent: Bool { overallScore >= 85 }
    var isGood: Bool { overallScore >= 70 && overallScore < 85 }
    var letterGrade: String { switch overallScore { case 90...100:"A+";case 85..<90:"A";case 80..<85:"A-";case 75..<80:"B+";case 70..<75:"B";case 65..<70:"B-";case 60..<65:"C+";case 55..<60:"C";case 50..<55:"C-";case 40..<50:"D";default:"F" } }
}
enum NoiseLevel: String, Codable { case none,minimal,low,moderate,high,severe }
enum ExposureAssessment: String, Codable { case perfect,slightOverexposed,slightUnderexposed,overexposed,underexposed,severelyOverexposed,severelyUnderexposed }
enum FocusAssessment: String, Codable { case sharp,good,acceptable,soft,blurry,severelyBlurry }
enum CompositionAssessment: String, Codable { case excellent,good,acceptable,needsWork,poor }
struct QualitySuggestion: Codable, Identifiable { let id:UUID; let category:SuggestionCategory; let title:String; let detail:String; let priority:SuggestionPriority; let icon:String }
enum SuggestionCategory: String, Codable, CaseIterable { case exposure,focus,composition,color,noise,general }
enum SuggestionPriority: String, Codable { case critical,high,medium,low,tip }
