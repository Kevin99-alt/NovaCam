import SwiftUI

// MARK: - Full Editor View
struct FullEditorView: View {
    @StateObject var vm: EditorViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showExport = false; @State private var showReset = false

    init(ciImage: CIImage) { _vm = StateObject(wrappedValue: EditorViewModel(ciImage: ciImage)) }
    init?(uiImage: UIImage) { guard let ci = CIImage(image: uiImage) else { return nil }; _vm = StateObject(wrappedValue: EditorViewModel(ciImage: ci)) }

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            previewArea
            categoryBar
            controlPanel
        }
        .background(Color.black.ignoresSafeArea())
        .confirmationDialog("Reset All?", isPresented: $showReset) {
            Button("Reset All", role: .destructive) { vm.resetAll() }; Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showExport) { ExportSheetView(vm: vm) }
    }

    private var toolbar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark").font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                    .frame(width: 36, height: 36).background(Circle().fill(.ultraThinMaterial))
            }
            Spacer()
            HStack(spacing: 12) {
                Button { vm.undo() } label: {
                    Image(systemName: "arrow.uturn.backward").foregroundColor(vm.canUndo ? .white : .white.opacity(0.3))
                }.disabled(!vm.canUndo)
                Button { vm.redo() } label: {
                    Image(systemName: "arrow.uturn.forward").foregroundColor(vm.canRedo ? .white : .white.opacity(0.3))
                }.disabled(!vm.canRedo)
            }
            Spacer()
            Button { vm.showBeforeAfter.toggle() } label: {
                Image(systemName: vm.showBeforeAfter ? "rectangle.fill.on.rectangle.fill" : "rectangle.on.rectangle")
                    .font(.system(size: 14)).foregroundColor(.white).frame(width: 36, height: 36)
                    .background(Circle().fill(.ultraThinMaterial))
            }
            Menu {
                Button { showExport = true } label: { Label("Export HEIF", systemImage: "square.and.arrow.up") }
                Button { showExport = true } label: { Label("Export JPEG", systemImage: "square.and.arrow.up.fill") }
                Divider()
                Button(role: .destructive) { showReset = true } label: { Label("Reset All", systemImage: "arrow.counterclockwise") }
            } label: {
                Image(systemName: "ellipsis.circle").font(.system(size: 16)).foregroundColor(.white)
                    .frame(width: 36, height: 36).background(Circle().fill(.ultraThinMaterial))
            }
        }.padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 4)
    }

    private var previewArea: some View {
        GeometryReader { geo in
            ZStack {
                if let p = vm.previewImage {
                    Image(uiImage: p).resizable().aspectRatio(contentMode: .fit)
                        .frame(maxWidth: geo.size.width, maxHeight: geo.size.height)
                } else { ProgressView().tint(.white).frame(maxWidth: .infinity, maxHeight: .infinity) }
                if vm.selectedTool == .curves { CurveEditorView(vm: vm).padding(16).frame(height: geo.size.height*0.55).frame(maxHeight: .infinity, alignment: .top) }
                if vm.selectedTool == .hsl { HSLEditorView(vm: vm).padding(16).frame(height: geo.size.height*0.55).frame(maxHeight: .infinity, alignment: .top) }
                if vm.selectedTool == .healing || vm.selectedTool == .clone { HealingCloneOverlay(vm: vm) }
                if vm.selectedTool == .crop { CropOverlayView(vm: vm) }
            }
        }
    }

    private var categoryBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(EditorToolCategory.allCases) { cat in
                    Button { vm.selectCategory(cat) } label: {
                        HStack(spacing: 4) {
                            Image(systemName: cat.icon).font(.system(size: 12))
                            Text(cat.rawValue.capitalized).font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(vm.selectedCategory == cat ? .orange : .white.opacity(0.6))
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Capsule().fill(vm.selectedCategory == cat ? Color.orange.opacity(0.15) : Color.white.opacity(0.05)))
                    }
                }
            }.padding(.horizontal, 12).padding(.vertical, 6)
        }
    }

    private var controlPanel: some View {
        VStack(spacing: 0) {
            toolPicker
            if needsSlider { sliderControl }
            HStack {
                Button("Reset") { vm.resetTool(vm.selectedTool) }.font(.system(size: 13)).foregroundColor(.orange).opacity(hasValue ? 1 : 0)
                Spacer()
                Text(valueLabel).font(.system(size: 13, design: .monospaced)).foregroundColor(.white.opacity(0.7))
            }.padding(.horizontal, 20).padding(.bottom, 8)
        }.background(.ultraThinMaterial)
    }

    private var toolPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(EditorTool.allCases.filter { $0.category == vm.selectedCategory }) { tool in
                    Button { vm.selectTool(tool) } label: {
                        VStack(spacing: 4) {
                            Image(systemName: tool.icon).font(.system(size: 18))
                            Text(tool.rawValue.capitalized).font(.system(size: 9))
                        }.foregroundColor(vm.selectedTool == tool ? .orange : .white.opacity(0.6)).frame(width: 54)
                    }
                }
            }.padding(.horizontal, 16).padding(.vertical, 8)
        }
    }

    private var needsSlider: Bool {
        ![.curves, .hsl, .healing, .clone, .crop, .rotate, .perspective].contains(vm.selectedTool)
    }

    private var sliderControl: some View {
        HStack(spacing: 12) {
            Image(systemName: "minus").font(.system(size: 10)).foregroundColor(.white.opacity(0.4))
            switch vm.selectedTool {
            case .exposure: Slider(value: vm.exposureB, in: -5...5, step: 0.01).tint(.orange)
            case .contrast: Slider(value: vm.contrastB, in: -1...1, step: 0.01).tint(.orange)
            case .highlights: Slider(value: vm.highlightsB, in: -1...1, step: 0.01).tint(.orange)
            case .shadows: Slider(value: vm.shadowsB, in: -1...1, step: 0.01).tint(.orange)
            case .temperature: Slider(value: vm.temperatureB, in: -1...1, step: 0.01).tint(.orange)
            case .saturation: Slider(value: vm.saturationB, in: -1...1, step: 0.01).tint(.orange)
            case .vibrance: Slider(value: vm.vibranceB, in: -1...1, step: 0.01).tint(.orange)
            case .sharpen: Slider(value: vm.sharpeningB, in: 0...1, step: 0.01).tint(.orange)
            case .noiseReduction: Slider(value: vm.noiseB, in: 0...1, step: 0.01).tint(.orange)
            case .clarity: Slider(value: vm.clarityB, in: -1...1, step: 0.01).tint(.orange)
            case .dehaze: Slider(value: vm.dehazeB, in: 0...1, step: 0.01).tint(.orange)
            case .vignette: Slider(value: vm.vignetteB, in: -1...1, step: 0.01).tint(.orange)
            case .grain: Slider(value: vm.grainB, in: 0...1, step: 0.01).tint(.orange)
            default: EmptyView()
            }
            Image(systemName: "plus").font(.system(size: 10)).foregroundColor(.white.opacity(0.4))
        }.padding(.horizontal, 20).padding(.vertical, 4)
    }

    private var hasValue: Bool {
        let s = vm.editorState
        let t = vm.selectedTool
        if t == .exposure { return s.exposure != 0 }
        if t == .contrast { return s.contrast != 0 }
        if t == .highlights { return s.highlights != 0 }
        if t == .shadows { return s.shadows != 0 }
        if t == .temperature { return s.temperature != 0 }
        if t == .saturation { return s.saturation != 0 }
        if t == .vibrance { return s.vibrance != 0 }
        if t == .sharpen { return s.sharpening != 0 }
        if t == .noiseReduction { return s.noiseReduction != 0 }
        if t == .clarity { return s.clarity != 0 }
        if t == .dehaze { return s.dehaze != 0 }
        if t == .vignette { return s.vignette != 0 }
        if t == .grain { return s.grain != 0 }
        if t == .curves { return s.rgbCurve != .linear || s.redCurve != .linear || s.greenCurve != .linear || s.blueCurve != .linear }
        if t == .hsl { return s.hslAdjustments.contains { $0.hueShift != 0 || $0.saturation != 0 || $0.luminance != 0 } }
        if t == .healing { return !s.healingSpots.isEmpty }
        if t == .clone { return !s.cloneSources.isEmpty }
        return false
    }
    private var valueLabel: String {
        let s = vm.editorState
        let t = vm.selectedTool
        if t == .exposure { return String(format: "%+.2f", s.exposure) }
        if t == .contrast { return String(format: "%+.2f", s.contrast) }
        if t == .highlights { return String(format: "%+.2f", s.highlights) }
        if t == .shadows { return String(format: "%+.2f", s.shadows) }
        if t == .temperature { return String(format: "%+.2f", s.temperature) }
        if t == .saturation { return String(format: "%+.2f", s.saturation) }
        if t == .vibrance { return String(format: "%+.2f", s.vibrance) }
        if t == .sharpen { return String(format: "%.2f", s.sharpening) }
        if t == .noiseReduction { return String(format: "%.2f", s.noiseReduction) }
        if t == .clarity { return String(format: "%+.2f", s.clarity) }
        if t == .dehaze { return String(format: "%.2f", s.dehaze) }
        if t == .vignette { return String(format: "%+.2f", s.vignette) }
        if t == .grain { return String(format: "%.2f", s.grain) }
        return ""
    }
}

// MARK: - Curve Editor
struct CurveEditorView: View {
    @ObservedObject var vm: EditorViewModel
    @State private var ch: CurveChannel = .rgb; @State private var dragIdx: Int?

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 0) {
                ForEach(CurveChannel.allCases, id: \.self) { c in
                    Button { ch = c } label: {
                        Text(c.rawValue).font(.system(size: 12, weight: .medium))
                            .foregroundColor(ch == c ? c.color : .white.opacity(0.5))
                            .frame(maxWidth: .infinity).padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: 6).fill(ch == c ? c.color.opacity(0.15) : Color.clear))
                    }
                }
            }
            curveCanvas
            HStack(spacing: 8) {
                ForEach([("Linear", ToneCurve.linear), ("Medium", .mediumContrast), ("Strong", .strongContrast), ("Fade", .fade)], id: \.0) { (label, curve) in
                    Button { vm.updateCurve(channel: ch, points: curve.controlPoints) } label: {
                        Text(label).font(.system(size: 10)).foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(Capsule().fill(Color.white.opacity(0.1)))
                    }
                }
            }
        }.padding(16).background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial))
    }

    private var curve: ToneCurve { vm.getCurve(ch) }
    private var curveCanvas: some View {
        GeometryReader { geo in
            ZStack {
                Canvas { ctx, size in
                    for i in 1..<4 {
                        let x = size.width*CGFloat(i)/4; let y = size.height*CGFloat(i)/4
                        var p = Path(); p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: size.height)); ctx.stroke(p, with: .color(.white.opacity(0.1)), lineWidth: 0.5)
                        p = Path(); p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: size.width, y: y)); ctx.stroke(p, with: .color(.white.opacity(0.1)), lineWidth: 0.5)
                    }
                    var d = Path(); d.move(to: CGPoint(x:0,y:size.height)); d.addLine(to: CGPoint(x:size.width,y:0)); ctx.stroke(d, with: .color(.white.opacity(0.08)), lineWidth: 0.5)
                }
                Path { path in
                    let pts = curve.controlPoints.map { CGPoint(x: $0.x*geo.size.width, y: geo.size.height - $0.y*geo.size.height) }
                    guard pts.count >= 2 else { return }; path.move(to: pts[0])
                    for i in 1..<pts.count { path.addLine(to: pts[i]) }
                }.stroke(ch.color, lineWidth: 2)
                ForEach(Array(curve.controlPoints.enumerated()), id: \.offset) { i, pt in
                    Circle().fill(i == dragIdx ? ch.color : Color.white).frame(width: 16, height: 16)
                        .overlay(Circle().stroke(ch.color.opacity(0.5), lineWidth: 1))
                        .position(x: pt.x*geo.size.width, y: geo.size.height - pt.y*geo.size.height)
                        .gesture(DragGesture().onChanged { v in
                            dragIdx = i
                            var pts = curve.controlPoints
                            let nx = max(0, min(1, v.location.x/geo.size.width))
                            let ny = max(0, min(1, 1-v.location.y/geo.size.height))
                            if i == 0 { pts[i] = CGPoint(x:0, y:CGFloat(ny)) }
                            else if i == pts.count-1 { pts[i] = CGPoint(x:1, y:CGFloat(ny)) }
                            else { pts[i] = CGPoint(x: CGFloat(nx), y: CGFloat(ny)) }
                            vm.updateCurve(channel: ch, points: pts)
                        }.onEnded { _ in dragIdx = nil })
                }
            }.onTapGesture(count: 2) { loc in
                vm.addCurvePoint(channel: ch, at: CGPoint(x: loc.x/geo.size.width, y: 1-loc.y/geo.size.height))
            }
        }
    }
}

// MARK: - HSL Editor
struct HSLEditorView: View {
    @ObservedObject var vm: EditorViewModel; @State private var hue: HSLHue = .red
    var adj: HSLAdjustment { vm.editorState.hslAdjustments.first(where: { $0.hue == hue }) ?? HSLAdjustment(hue: hue) }
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ForEach(HSLHue.allCases) { h in
                    Button { hue = h } label: {
                        VStack(spacing: 4) {
                            Circle().fill(h.color).frame(width: 28, height: 28)
                                .overlay(Circle().stroke(hue == h ? Color.white : Color.clear, lineWidth: 2))
                            Text(String(h.rawValue.prefix(1))).font(.system(size: 9)).foregroundColor(.white.opacity(hue == h ? 1 : 0.4))
                        }
                    }
                }
            }
            VStack(spacing: 14) {
                hslSlider("Hue", "circle.lefthalf.filled", Binding(get:{adj.hueShift}, set:{vm.updateHSL(hue:hue, hs:$0, sat:nil, lum:nil)}), -180...180, "%.0f°")
                hslSlider("Saturation", "drop.fill", Binding(get:{adj.saturation}, set:{vm.updateHSL(hue:hue, hs:nil, sat:$0, lum:nil)}), -1...1, "%+.0f")
                hslSlider("Luminance", "sun.max.fill", Binding(get:{adj.luminance}, set:{vm.updateHSL(hue:hue, hs:nil, sat:nil, lum:$0)}), -1...1, "%+.0f")
            }
            HStack { Button("Reset \(hue.rawValue)"){vm.resetHSL(hue)}.font(.system(size:12)).foregroundColor(.orange); Spacer(); Button("Reset All"){vm.resetAllHSL()}.font(.system(size:12)).foregroundColor(.orange.opacity(0.7)) }
        }.padding(16).background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial))
    }
    private func hslSlider(_ label: String, _ icon: String, _ value: Binding<Double>, _ range: ClosedRange<Double>, _ fmt: String) -> some View {
        HStack(spacing: 10) {
            HStack(spacing: 4) { Image(systemName: icon).font(.system(size:10)); Text(label).font(.system(size:11)) }.foregroundColor(.white.opacity(0.6)).frame(width:60, alignment:.leading)
            Slider(value: value, in: range, step: 0.01).tint(hue.color)
            Text(String(format: fmt, value.wrappedValue)).font(.system(size:11, design:.monospaced)).foregroundColor(.white.opacity(0.7)).frame(width:36, alignment:.trailing)
        }
    }
}

// MARK: - Healing / Clone Overlay
struct HealingCloneOverlay: View {
    @ObservedObject var vm: EditorViewModel; @State private var srcPt: CGPoint?; @State private var radius: CGFloat = 30
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.clear.contentShape(Rectangle())
                ForEach(vm.editorState.healingSpots) { s in
                    Circle().stroke(Color.white.opacity(0.5), lineWidth: 1)
                        .frame(width: s.radius*geo.size.width*2, height: s.radius*geo.size.width*2)
                        .position(x: s.position.x*geo.size.width, y: s.position.y*geo.size.height)
                }
                ForEach(vm.editorState.cloneSources) { c in
                    Path { p in p.move(to: CGPoint(x:c.sourcePosition.x*geo.size.width,y:c.sourcePosition.y*geo.size.height)); p.addLine(to: CGPoint(x:c.targetPosition.x*geo.size.width,y:c.targetPosition.y*geo.size.height)) }.stroke(Color.green.opacity(0.6), lineWidth:1)
                    Circle().stroke(Color.green, lineWidth:1.5).frame(width:c.radius*geo.size.width*2,height:c.radius*geo.size.width*2).position(x:c.sourcePosition.x*geo.size.width,y:c.sourcePosition.y*geo.size.height)
                    Circle().stroke(Color.white, lineWidth:1.5).frame(width:c.radius*geo.size.width*2,height:c.radius*geo.size.width*2).position(x:c.targetPosition.x*geo.size.width,y:c.targetPosition.y*geo.size.height)
                }
            }
            .gesture(DragGesture(minimumDistance:0).onChanged { v in
                let pt = CGPoint(x:v.location.x/geo.size.width, y:v.location.y/geo.size.height)
                if vm.selectedTool == .healing { vm.addHealingSpot(at:pt, radius:radius/geo.size.width) }
                else { if srcPt == nil { srcPt = pt } else if let s = srcPt { vm.paintClone(from:s, to:pt, radius:radius/geo.size.width) } }
            }.onEnded { _ in srcPt = nil; vm.pushUndo(vm.selectedTool.rawValue) })
        }
        .overlay(alignment:.bottom) {
            HStack {
                Image(systemName:"circle.dotted").font(.system(size:12)); Slider(value:$radius, in:5...100).tint(.orange).frame(width:120)
                Text("\(Int(radius))px").font(.system(size:12,design:.monospaced))
            }.foregroundColor(.white).padding(.horizontal,16).padding(.vertical,8).background(Capsule().fill(.ultraThinMaterial)).padding(.bottom,8)
        }
    }
}

// MARK: - Crop Overlay
struct CropOverlayView: View {
    @ObservedObject var vm: EditorViewModel; @State private var rect: CGRect = CGRect(x:0.05,y:0.05,width:0.9,height:0.9)
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.opacity(0.5).mask(
                    Rectangle().fill(Color.black).overlay(
                        Rectangle().fill(Color.white).frame(width:rect.width*geo.size.width, height:rect.height*geo.size.height).position(x:rect.midX*geo.size.width, y:rect.midY*geo.size.height).blendMode(.destinationOut)
                    )
                )
                Rectangle().stroke(Color.white, lineWidth:1.5).frame(width:rect.width*geo.size.width, height:rect.height*geo.size.height).position(x:rect.midX*geo.size.width, y:rect.midY*geo.size.height)
                Path { p in
                    let r = CGRect(x:rect.minX*geo.size.width,y:rect.minY*geo.size.height,width:rect.width*geo.size.width,height:rect.height*geo.size.height)
                    p.move(to:CGPoint(x:r.minX+r.width/3,y:r.minY));p.addLine(to:CGPoint(x:r.minX+r.width/3,y:r.maxY));p.move(to:CGPoint(x:r.minX+r.width*2/3,y:r.minY));p.addLine(to:CGPoint(x:r.minX+r.width*2/3,y:r.maxY))
                    p.move(to:CGPoint(x:r.minX,y:r.minY+r.height/3));p.addLine(to:CGPoint(x:r.maxX,y:r.minY+r.height/3));p.move(to:CGPoint(x:r.minX,y:r.minY+r.height*2/3));p.addLine(to:CGPoint(x:r.maxX,y:r.minY+r.height*2/3))
                }.stroke(Color.white.opacity(0.3), lineWidth:0.5)
            }
        }
    }
}

// MARK: - Export Sheet
struct ExportSheetView: View {
    @ObservedObject var vm: EditorViewModel; @State private var fmt: ExportFmt = .heif; @State private var q: Double = 0.92; @State private var exporting = false; @Environment(\.dismiss) var dismiss
    enum ExportFmt: String, CaseIterable { case heif="HEIF", jpeg="JPEG" }
    var body: some View {
        NavigationStack {
            VStack(spacing:20) {
                if let p = vm.previewImage { Image(uiImage:p).resizable().aspectRatio(contentMode:.fit).frame(maxHeight:250).clipShape(RoundedRectangle(cornerRadius:12)) }
                Picker("Format", selection:$fmt) { ForEach(ExportFmt.allCases, id:\.self){f in Text(f.rawValue).tag(f)} }.pickerStyle(.segmented).padding(.horizontal)
                VStack(spacing:8) { HStack { Text("Quality").font(.subheadline); Spacer(); Text("\(Int(q*100))%").font(.subheadline.monospaced()) }; Slider(value:$q, in:0.1...1, step:0.01).tint(.orange) }.padding(.horizontal)
                Button {
                    exporting = true
                    Task { @MainActor in
                        _ = fmt == .heif ? vm.exportHEIF(quality:Float(q)) : vm.exportJPEG(quality:Float(q))
                        exporting = false
                        dismiss()
                    }
                } label: {
                    HStack { if exporting { ProgressView().tint(.white) }; Text(exporting ? "Exporting..." : "Export") }.font(.headline).foregroundColor(.white).frame(maxWidth:.infinity).padding(.vertical,14).background(RoundedRectangle(cornerRadius:12).fill(Color.orange))
                }.disabled(exporting).padding(.horizontal)
            }.padding(.top).navigationTitle("Export").navigationBarTitleDisplayMode(.inline).toolbar { ToolbarItem(placement:.cancellationAction) { Button("Cancel"){dismiss()} } }
        }.presentationDetents([.medium, .large])
    }
}
