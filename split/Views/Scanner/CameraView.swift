import SwiftUI
@preconcurrency import AVFoundation

struct CameraView: View {
    @Binding var capturedImage: UIImage?
    var onOpenPhotoLibrary: (() -> Void)?
    @Environment(\.dismiss) var dismiss

    @StateObject private var camera = CameraModel()

    var body: some View {
        ZStack {
            // 相機預覽
            CameraPreviewView(session: camera.session)
                .ignoresSafeArea()

            // 控制項覆蓋層
            VStack {
                // 頂部控制列
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }

                    Spacer()

                    Button(action: { camera.toggleFlash() }) {
                        Image(systemName: camera.flashMode == .off ? "bolt.slash.fill" :
                                         camera.flashMode == .on ? "bolt.fill" : "bolt.badge.automatic.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(camera.flashMode == .on ? .yellow : .white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)

                Spacer()

                // 底部控制列
                HStack(alignment: .center, spacing: 60) {
                    // 相簿按鈕
                    Button(action: {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onOpenPhotoLibrary?()
                        }
                    }) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }

                    // 拍照按鈕
                    Button(action: {
                        camera.capturePhoto { image in
                            capturedImage = image
                            dismiss()
                        }
                    }) {
                        ZStack {
                            Circle()
                                .stroke(Color.white, lineWidth: 4)
                                .frame(width: 70, height: 70)

                            Circle()
                                .fill(Color.white)
                                .frame(width: 58, height: 58)
                        }
                    }
                    .disabled(camera.isCapturing)

                    // 切換鏡頭按鈕
                    Button(action: { camera.switchCamera() }) {
                        Image(systemName: "camera.rotate.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                }
                .padding(.bottom, 30)
            }
            .safeAreaPadding(.top, 8)

            // 拍照中指示器
            if camera.isCapturing {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
        }
        .onAppear {
            camera.checkPermissionAndSetup()
        }
        .onDisappear {
            camera.stopSession()
        }
        .statusBarHidden(true)
    }
}

// MARK: - 相機預覽視圖
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = CameraPreviewUIView()
        view.session = session
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

class CameraPreviewUIView: UIView {
    var session: AVCaptureSession? {
        didSet {
            guard let session = session else { return }
            previewLayer.session = session
        }
    }

    private var previewLayer: AVCaptureVideoPreviewLayer!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupPreviewLayer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupPreviewLayer()
    }

    private func setupPreviewLayer() {
        previewLayer = AVCaptureVideoPreviewLayer()
        previewLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(previewLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds
    }
}

// MARK: - 相機模型
@MainActor
class CameraModel: NSObject, ObservableObject {
    @Published var flashMode: AVCaptureDevice.FlashMode = .auto
    @Published var isCapturing = false

    nonisolated(unsafe) let session = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private var currentDevice: AVCaptureDevice?
    private var currentPosition: AVCaptureDevice.Position = .back
    private var photoCompletion: ((UIImage?) -> Void)?

    override init() {
        super.init()
    }

    func checkPermissionAndSetup() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    Task { @MainActor in
                        self?.setupSession()
                    }
                }
            }
        default:
            break
        }
    }

    private func setupSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentPosition),
              let input = try? AVCaptureDeviceInput(device: device) else {
            session.commitConfiguration()
            return
        }

        if session.canAddInput(input) {
            session.addInput(input)
            currentDevice = device
        }

        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            if let maxDimensions = currentDevice?.activeFormat.supportedMaxPhotoDimensions.max(by: { $0.width < $1.width }) {
                photoOutput.maxPhotoDimensions = maxDimensions
            }
        }

        session.commitConfiguration()

        Task.detached { [weak self] in
            self?.session.startRunning()
        }
    }

    func stopSession() {
        if session.isRunning {
            Task.detached { [weak self] in
                self?.session.stopRunning()
            }
        }
    }

    func toggleFlash() {
        switch flashMode {
        case .off:
            flashMode = .on
        case .on:
            flashMode = .auto
        case .auto:
            flashMode = .off
        @unknown default:
            flashMode = .auto
        }
    }

    func switchCamera() {
        session.beginConfiguration()

        if let currentInput = session.inputs.first as? AVCaptureDeviceInput {
            session.removeInput(currentInput)
        }

        currentPosition = currentPosition == .back ? .front : .back

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentPosition),
              let input = try? AVCaptureDeviceInput(device: device) else {
            session.commitConfiguration()
            return
        }

        if session.canAddInput(input) {
            session.addInput(input)
            currentDevice = device
        }

        session.commitConfiguration()
    }

    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        guard !isCapturing else { return }

        isCapturing = true
        photoCompletion = completion

        let settings = AVCapturePhotoSettings()

        if currentPosition == .back, let device = currentDevice, device.hasFlash {
            settings.flashMode = flashMode
        }

        photoOutput.capturePhoto(with: settings, delegate: self)
    }
}

// MARK: - 拍照代理
extension CameraModel: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        let imageData = photo.fileDataRepresentation()

        Task { @MainActor [weak self] in
            self?.isCapturing = false

            guard error == nil,
                  let data = imageData,
                  let image = UIImage(data: data) else {
                self?.photoCompletion?(nil)
                return
            }

            self?.photoCompletion?(image)
        }
    }
}
