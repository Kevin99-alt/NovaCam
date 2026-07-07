import SwiftUI
import AVFoundation

struct CameraPreviewView: UIViewRepresentable {
    var session: AVCaptureSession?
    var onTapToFocus: ((CGPoint) -> Void)?
    var onPinchToZoom: ((CGFloat) -> Void)?
    var onDoubleTap: (() -> Void)?
    var onLongPress: ((CGPoint) -> Void)?

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.backgroundColor = .black
        view.setupGestures(coordinator: context.coordinator)
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        uiView.updateSession(session)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onTapToFocus, onPinchToZoom, onDoubleTap, onLongPress)
    }

    class Coordinator: NSObject {
        let onTapToFocus: ((CGPoint) -> Void)?
        let onPinchToZoom: ((CGFloat) -> Void)?
        let onDoubleTap: (() -> Void)?
        let onLongPress: ((CGPoint) -> Void)?
        var lastZoom: CGFloat = 1.0

        init(_ tap: ((CGPoint) -> Void)?, _ pinch: ((CGFloat) -> Void)?,
             _ double: (() -> Void)?, _ long: ((CGPoint) -> Void)?) {
            onTapToFocus = tap; onPinchToZoom = pinch
            onDoubleTap = double; onLongPress = long
        }

        @objc func handleTap(_ g: UITapGestureRecognizer) {
            guard let v = g.view else { return }
            onTapToFocus?(CGPoint(x: g.location(in: v).x / v.bounds.width,
                                   y: g.location(in: v).y / v.bounds.height))
        }
        @objc func handleDoubleTap(_ g: UITapGestureRecognizer) { onDoubleTap?() }
        @objc func handlePinch(_ g: UIPinchGestureRecognizer) {
            switch g.state {
            case .began: lastZoom = 1.0
            case .changed: let d = g.scale / lastZoom; lastZoom = g.scale; onPinchToZoom?(d)
            default: break
            }
        }
        @objc func handleLongPress(_ g: UILongPressGestureRecognizer) {
            guard g.state == .began, let v = g.view else { return }
            onLongPress?(CGPoint(x: g.location(in: v).x / v.bounds.width,
                                  y: g.location(in: v).y / v.bounds.height))
        }
    }
}

final class CameraPreviewUIView: UIView {
    private let previewLayer = AVCaptureVideoPreviewLayer()
    private var focusBox: CAShapeLayer?

    override init(frame: CGRect) {
        super.init(frame: frame)
        previewLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(previewLayer)
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        previewLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(previewLayer)
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds
    }

    func updateSession(_ session: AVCaptureSession?) {
        guard previewLayer.session !== session else { return }
        if session != nil {
            UIView.transition(with: self, duration: 0.2, options: .transitionCrossDissolve) {
                self.previewLayer.session = session
            }
        } else {
            previewLayer.session = session
        }
    }

    func setupGestures(coordinator: CameraPreviewView.Coordinator) {
        let tap = UITapGestureRecognizer(target: coordinator, action: #selector(CameraPreviewView.Coordinator.handleTap(_:)))
        let dblTap = UITapGestureRecognizer(target: coordinator, action: #selector(CameraPreviewView.Coordinator.handleDoubleTap(_:)))
        dblTap.numberOfTapsRequired = 2
        tap.require(toFail: dblTap)
        let pinch = UIPinchGestureRecognizer(target: coordinator, action: #selector(CameraPreviewView.Coordinator.handlePinch(_:)))
        let longPress = UILongPressGestureRecognizer(target: coordinator, action: #selector(CameraPreviewView.Coordinator.handleLongPress(_:)))
        longPress.minimumPressDuration = 0.5
        addGestureRecognizer(tap)
        addGestureRecognizer(dblTap)
        addGestureRecognizer(pinch)
        addGestureRecognizer(longPress)
        tap.delegate = self
        pinch.delegate = self
    }
}

extension CameraPreviewUIView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ g: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith o: UIGestureRecognizer) -> Bool {
        return g is UIPinchGestureRecognizer || o is UIPinchGestureRecognizer
    }
}
