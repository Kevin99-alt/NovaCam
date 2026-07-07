import Foundation; import CoreGraphics
struct SceneAnalysisResult { let classification: SceneClassification; let subjects: [DetectedSubject]; let lighting: LightingClassification; let composition: CompositionAnalysis; let timestamp: Date; let confidence: Float }
enum SceneClassification: String, CaseIterable { case portrait,group,landscape,food,pet,document,nightScene,sunset,sunrise,macro,indoor,outdoor,cityscape,beach,snow,text,qrCode,businessCard,receipt,idCard,passport,unknown
    var icon: String { switch self { case .portrait:"person.fill";case .group:"person.3.fill";case .landscape:"mountain.2.fill";case .food:"fork.knife";case .pet:"pawprint.fill";case .document:"doc.text.fill";case .nightScene:"moon.stars.fill";case .sunset:"sunset.fill";case .sunrise:"sunrise.fill";case .macro:"ant.fill";case .indoor:"house.fill";case .outdoor:"tree.fill";case .cityscape:"building.2.fill";case .beach:"beach.umbrella.fill";case .snow:"snowflake";case .text:"text.alignleft";case .qrCode:"qrcode";case .businessCard:"person.text.rectangle.fill";case .receipt:"receipt";case .idCard:"wallet.pass.fill";case .passport:"book.closed.fill";case .unknown:"questionmark.circle.fill" } }
    var suggestedPreset: EnhancementPreset { switch self { case .portrait,.group: .portrait; case .landscape,.beach,.snow,.cityscape,.sunset,.sunrise: .landscape; case .food: .auto; case .nightScene: .night; default: .auto } }
}
struct DetectedSubject: Identifiable { let id = UUID(); let type: SubjectType; let boundingBox: CGRect; let confidence: Float; let attributes: [SubjectAttribute] }
enum SubjectType: String { case person,face,eye,pet,cat,dog,food,plate,document,text,qrCode,barcode,building,car,plant,flower,object }
enum SubjectAttribute: String { case smiling,eyesOpen,eyesClosed,lookingAtCamera,backlit,underexposed,overexposed,inFocus,blurred,moving }
struct LightingClassification { let type: LightingType; let brightnessLevel: Float; let colorTemperature: Float; let isBacklit: Bool; let hasMixedLighting: Bool; let lowLightConfidence: Float; let suggestedISO: Float? }
enum LightingType: String { case natural,golden,overcast,indoorTungsten,indoorFluorescent,indoorLED,lowLight,mixed,harsh,backlit }
struct CompositionAnalysis { let dominantLines: [CompositionLine]; let symmetryScore: Float; let balanceScore: Float; let ruleOfThirdsAlignment: Float; let goldenRatioAlignment: Float; let hasLeadingLines: Bool; let negativeSpacePercentage: Float; let horizonAngle: Float }
enum CompositionLine { case horizontal(CGFloat); case vertical(CGFloat); case diagonal(slope: CGFloat, intercept: CGFloat) }
struct BlurAssessment { let isBlurry: Bool; let blurScore: Float; let blurType: BlurType; let motionBlur: Bool; let lensSmudgeLikelihood: Float }
enum BlurType: String { case none,focus,motion,lens,depthOfField }
struct PhotographySuggestion: Identifiable { let id = UUID(); let category: SuggestionCategory; let message: String; let icon: String; let severity: SuggestionSeverity }
enum SuggestionSeverity: String { case warning,info,tip,success }
