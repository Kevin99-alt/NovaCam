import SwiftUI
struct GridOverlayView: View { let type: GridType
    var body: some View { GeometryReader { geo in
        switch type { case .ruleOfThirds: ruleOfThirds(geo.size); case .goldenRatio: golden(geo.size); case .crosshair: crosshair(geo.size); case .square: square(geo.size); case .off: EmptyView() }
    }.allowsHitTesting(false) }
    private func ruleOfThirds(_ s:CGSize)->some View { Path{ p in let tx=s.width/3,_2x=s.width*2/3,ty=s.height/3,_2y=s.height*2/3; p.move(to:CGPoint(x:tx,y:0));p.addLine(to:CGPoint(x:tx,y:s.height));p.move(to:CGPoint(x:_2x,y:0));p.addLine(to:CGPoint(x:_2x,y:s.height));p.move(to:CGPoint(x:0,y:ty));p.addLine(to:CGPoint(x:s.width,y:ty));p.move(to:CGPoint(x:0,y:_2y));p.addLine(to:CGPoint(x:s.width,y:_2y)) }.stroke(Color.white.opacity(0.35),lineWidth:1) }
    private func golden(_ s:CGSize)->some View { let phi:CGFloat=1.618,x1=s.width/phi,x2=s.width-x1,y1=s.height/phi,y2=s.height-y1; return Path{ p in p.move(to:CGPoint(x:x1,y:0));p.addLine(to:CGPoint(x:x1,y:s.height));p.move(to:CGPoint(x:x2,y:0));p.addLine(to:CGPoint(x:x2,y:s.height));p.move(to:CGPoint(x:0,y:y1));p.addLine(to:CGPoint(x:s.width,y:y1));p.move(to:CGPoint(x:0,y:y2));p.addLine(to:CGPoint(x:s.width,y:y2)) }.stroke(Color.white.opacity(0.3),lineWidth:1) }
    private func crosshair(_ s:CGSize)->some View { Path{ p in p.move(to:CGPoint(x:s.width/2,y:0));p.addLine(to:CGPoint(x:s.width/2,y:s.height));p.move(to:CGPoint(x:0,y:s.height/2));p.addLine(to:CGPoint(x:s.width,y:s.height/2)) }.stroke(Color.white.opacity(0.4),lineWidth:1) }
    private func square(_ s:CGSize)->some View { let sz=min(s.width,s.height)*0.85,ox=(s.width-sz)/2,oy=(s.height-sz)/2; return Path{ p in p.addRect(CGRect(x:ox,y:oy,width:sz,height:sz)) }.stroke(Color.white.opacity(0.35),lineWidth:1.5) }
}
struct LevelIndicatorView: View { let angle: CGFloat
    var body: some View { VStack{Spacer();HStack{Spacer();ZStack{
        RoundedRectangle(cornerRadius:2).fill(Color.white.opacity(0.3)).frame(width:80,height:4)
        RoundedRectangle(cornerRadius:1).fill(Color.white).frame(width:2,height:16).offset(y:-8)
        Circle().fill(abs(angle)<0.02 ? .green : abs(angle)<0.05 ? .yellow : .orange).frame(width:10,height:10).offset(x:min(max(angle*100,-40),40))
        Image(systemName:"arrowtriangle.down.fill").font(.system(size:8)).foregroundColor(abs(angle)<0.02 ? .green : abs(angle)<0.05 ? .yellow : .orange).offset(x:min(max(angle*100,-40),40),y:12)
    }.frame(width:100,height:40).background(RoundedRectangle(cornerRadius:10).fill(.ultraThinMaterial));Spacer()}.padding(.bottom,180)}.allowsHitTesting(false) }
}
struct HistogramView: View { let red:[Float]; let green:[Float]; let blue:[Float]; let luminance:[Float]
    var body: some View { ZStack { RoundedRectangle(cornerRadius:8).fill(.ultraThinMaterial); Canvas { ctx,size in draw(&ctx,size,red,.red,0.5); draw(&ctx,size,green,.green,0.5); draw(&ctx,size,blue,.blue,0.5); draw(&ctx,size,luminance,.white,0.8) }.padding(4) }.overlay(RoundedRectangle(cornerRadius:8).stroke(Color.white.opacity(0.2),lineWidth:1)) }
    private func draw(_ ctx:inout GraphicsContext,_ s:CGSize,_ d:[Float],_ c:Color,_ o:Double) { guard !d.isEmpty else{return}; let mx=d.max() ?? 1,bw=s.width/CGFloat(d.count); var p=Path(); for(i,v)in d.enumerated() { let n=CGFloat(v/max(mx,1)),x=CGFloat(i)*bw,h=n*s.height; if h>0{p.addRect(CGRect(x:x,y:s.height-h,width:max(bw,1),height:h))} }; ctx.fill(p,with:.color(c.opacity(o))) }
}
