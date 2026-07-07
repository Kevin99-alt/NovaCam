import Foundation; import CoreML; import Vision; import CoreImage
final class SceneAnalysisService: AIServiceProtocol {
    private let queue = DispatchQueue(label:"com.novacam.ai", qos:.userInitiated)
    private var useML: Bool { MLModelManager.shared.isReady && MLModelManager.shared.sceneClassifier != nil }
    func analyzeScene(from buf:CVPixelBuffer) async throws -> SceneAnalysisResult {
        try await withCheckedThrowingContinuation { c in queue.async { Task {
            let cls: SceneClassification; let subjs: [DetectedSubject]; let light: LightingClassification
            if self.useML, let m = MLModelManager.shared.sceneClassifier, let r = try? await self.classifyML(buf, m) { cls = r }
            else { cls = self.classifyHeuristic(buf) }
            subjs = (try? await self.detectSubjects(in:buf)) ?? []
            light = (try? await self.classifyLighting(from:buf)) ?? LightingClassification(type:.natural,brightnessLevel:0.5,colorTemperature:5500,isBacklit:false,hasMixedLighting:false,lowLightConfidence:0,suggestedISO:nil)
            c.resume(returning:SceneAnalysisResult(classification:cls,subjects:subjs,lighting:light,composition:CompositionAnalysis(dominantLines:[],symmetryScore:0.5,balanceScore:0.6,ruleOfThirdsAlignment:0.5,goldenRatioAlignment:0.4,hasLeadingLines:false,negativeSpacePercentage:0.3,horizonAngle:0),timestamp:Date(),confidence:0.85))
        } } }
    }
    private func classifyML(_ buf:CVPixelBuffer, _ model:VNCoreMLModel) async throws -> SceneClassification {
        try await withCheckedThrowingContinuation { c in
            let rq=VNCoreMLRequest(model:model){ rq,_ in
                guard let rs=rq.results as? [VNClassificationObservation], let top=rs.first else { c.resume(throwing:AIErr.fail("no results")); return }
                c.resume(returning: SceneClassification(rawValue:top.identifier) ?? .unknown)
            }; rq.imageCropAndScaleOption = .centerCrop
            try? VNImageRequestHandler(cvPixelBuffer:buf,options:[:]).perform([rq])
        }
    }
    private func classifyHeuristic(_ buf:CVPixelBuffer) -> SceneClassification {
        let (b,_)=brightness(buf); let ct=colorTemp(buf); let ed=edgeDensity(buf)
        if b<0.15{return .nightScene}; if ct>2800&&ct<3500&&b>0.4&&b<0.7{return .sunset}
        if ed>0.6{return .macro}; if b<0.25{return .indoor}; if ct>5500&&b>0.6{return .outdoor}
        if ed>0.5{return .landscape}; return .unknown
    }
    func detectSubjects(in buf:CVPixelBuffer) async throws -> [DetectedSubject] {
        var s:[DetectedSubject]=[]
        let faceRq=VNDetectFaceRectanglesRequest(); let handler=VNImageRequestHandler(cvPixelBuffer:buf,options:[:])
        try? handler.perform([faceRq])
        if let rs=faceRq.results{ for o in rs { s.append(DetectedSubject(type:.face,boundingBox:o.boundingBox,confidence:o.confidence,attributes:[])) } }
        let barRq=VNDetectBarcodesRequest()
        try? handler.perform([barRq])
        if let rs=barRq.results{ for b in rs { s.append(DetectedSubject(type:b.symbology == .qr ? .qrCode : .barcode,boundingBox:b.boundingBox,confidence:b.confidence,attributes:[])) } }
        return s
    }
    func classifyLighting(from buf:CVPixelBuffer) async throws -> LightingClassification {
        let (b,_)=brightness(buf); let ct=colorTemp(buf); let bl=backlit(buf)
        let t:LightingType = b<0.12 ? .lowLight : bl ? .backlit : ct>3000&&ct<4500&&b>0.4 ? .golden : ct<3000 ? .indoorTungsten : ct>6500 ? .harsh : .natural
        let iso:Float? = b<0.15 ? 800 : b<0.25 ? 400 : b<0.4 ? 200 : nil
        return LightingClassification(type:t,brightnessLevel:b,colorTemperature:ct,isBacklit:bl,hasMixedLighting:false,lowLightConfidence:b<0.15 ? 1-b : 0,suggestedISO:iso)
    }
    func computeQualityScore(from buf:CVPixelBuffer, settings:CaptureSettings) async throws -> PhotoQualityScore {
        let (b,_)=brightness(buf); let ed=edgeDensity(buf); let nl=noise(buf); let ct=colorTemp(buf)
        let sharp=Int(min(100,ed*120)); let expDev=abs(b-0.5)
        let exp:Int=expDev<0.05 ? 95 : expDev<0.1 ? 85 : expDev<0.2 ? 70 : expDev<0.3 ? 50 : 30
        let nse=Int(100-min(90,nl*100)); let col=Int(100-min(60,abs(ct-5500)/5500*60)); let cmp=70
        let ovr=(sharp+exp+nse+col+cmp)/5
        return PhotoQualityScore(overallScore:ovr,sharpnessScore:sharp,exposureScore:exp,compositionScore:cmp,noiseScore:nse,colorScore:col,dynamicRangeEstimate:8,blurPercentage:Float(100-sharp)/100,overexposedPercentage:b>0.6 ? (b-0.6)*2 : 0,underexposedPercentage:b<0.2 ? (0.2-b)*2 : 0,noiseLevel:nl<0.25 ? .minimal : nl<0.5 ? .low : nl<0.75 ? .moderate : .high,whiteBalanceAccuracy:1-Float(abs(ct-5500)/5500),exposureAssessment:expDev<0.05 ? .perfect : expDev<0.12 ? (b>0.5 ? .slightOverexposed : .slightUnderexposed) : .overexposed,focusAssessment:sharp>90 ? .sharp : sharp>75 ? .good : sharp>60 ? .acceptable : .soft,compositionAssessment:cmp>75 ? .good : .acceptable,suggestions:[])
    }
    func generateSuggestions(from a:SceneAnalysisResult, quality q:PhotoQualityScore) -> [PhotographySuggestion] {
        var s:[PhotographySuggestion]=[]
        if a.lighting.type == .lowLight { s.append(PhotographySuggestion(category:.exposure,message:"Low light — hold steady",icon:"moon.stars.fill",severity:.warning)) }
        if a.lighting.isBacklit { s.append(PhotographySuggestion(category:.exposure,message:"Subject is backlit",icon:"sun.max.trianglebadge.exclamationmark",severity:.warning)) }
        if q.focusAssessment == .soft || q.focusAssessment == .blurry { s.append(PhotographySuggestion(category:.focus,message:"Tap to focus",icon:"camera.viewfinder",severity:.warning)) }
        if abs(a.composition.horizonAngle) > 0.05 { s.append(PhotographySuggestion(category:.composition,message:"Horizon tilted",icon:"level",severity:.info)) }
        if q.overallScore >= 85 { s.append(PhotographySuggestion(category:.general,message:"Great shot!",icon:"star.fill",severity:.success)) }
        return s
    }
    func detectBlur(in buf:CVPixelBuffer) async throws -> BlurAssessment { let ed=edgeDensity(buf); return BlurAssessment(isBlurry:ed<0.3,blurScore:ed,blurType:ed<0.3 ? .focus : .none,motionBlur:false,lensSmudgeLikelihood:ed<0.15 ? 0.7 : 0) }
    private func brightness(_ buf:CVPixelBuffer) -> (Float,Float) {
        CVPixelBufferLockBaseAddress(buf,.readOnly); defer{CVPixelBufferUnlockBaseAddress(buf,.readOnly)}
        guard let base=CVPixelBufferGetBaseAddress(buf) else { return (0.5,0.1) }
        let w=CVPixelBufferGetWidth(buf), h=CVPixelBufferGetHeight(buf), bpr=CVPixelBufferGetBytesPerRow(buf)
        var t:Float=0, tsq:Float=0; let n=1000
        for _ in 0..<n { let x=Int.random(in:0..<w), y=Int.random(in:0..<h); let o=y*bpr+x*4; let p=base.advanced(by:o).assumingMemoryBound(to:UInt8.self); let l=0.299*Float(p[0])+0.587*Float(p[1])+0.114*Float(p[2]); t+=l; tsq+=l*l }
        let m=t/Float(n)/255, v=tsq/Float(n)/65025-m*m; return (m,sqrt(max(0,v)))
    }
    private func colorTemp(_ buf:CVPixelBuffer) -> Float { CVPixelBufferLockBaseAddress(buf,.readOnly); defer{CVPixelBufferUnlockBaseAddress(buf,.readOnly)}; guard let base=CVPixelBufferGetBaseAddress(buf) else { return 5500 }; let w=CVPixelBufferGetWidth(buf),h=CVPixelBufferGetHeight(buf),bpr=CVPixelBufferGetBytesPerRow(buf); var r:Float=0,b:Float=0; for _ in 0..<100 { let x=Int.random(in:0..<w),y=Int.random(in:0..<h),o=y*bpr+x*4,p=base.advanced(by:o).assumingMemoryBound(to:UInt8.self); r+=Float(p[0]); b+=Float(p[2]) }; return 5500*r/max(b,1) }
    private func edgeDensity(_ buf:CVPixelBuffer) -> Float { let (_,s)=brightness(buf); return min(1,s*5) }
    private func noise(_ buf:CVPixelBuffer) -> Float { let (m,s)=brightness(buf); return m<0.2 ? min(1,s*3) : min(1,s*1.5) }
    private func backlit(_ buf:CVPixelBuffer) -> Bool { CVPixelBufferLockBaseAddress(buf,.readOnly); defer{CVPixelBufferUnlockBaseAddress(buf,.readOnly)}; guard let base=CVPixelBufferGetBaseAddress(buf) else {return false}; let w=CVPixelBufferGetWidth(buf),h=CVPixelBufferGetHeight(buf),bpr=CVPixelBufferGetBytesPerRow(buf); var e:Float=0; for x in stride(from:0,to:w,by:w/10){let p=base.advanced(by:x*4).assumingMemoryBound(to:UInt8.self);e+=0.299*Float(p[0])+0.587*Float(p[1])+0.114*Float(p[2])}; let c=base.advanced(by:(h/2)*bpr+(w/2)*4).assumingMemoryBound(to:UInt8.self); let cb=0.299*Float(c[0])+0.587*Float(c[1])+0.114*Float(c[2]); return e/255>cb/255*1.5 }
    enum AIErr: LocalizedError { case fail(String); var errorDescription: String? { if case .fail(let r)=self{return r}; return nil } }
}
