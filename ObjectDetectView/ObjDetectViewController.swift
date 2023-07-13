import SwiftUI
import AVFoundation
import Vision


class ObjDetectViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    private var permissionGranted = false // Flag for permission
    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    
    var screenRect: CGRect! = nil // For view dimensions
    var previewLayer = AVCaptureVideoPreviewLayer()
    
    // Detector
    private var videoOutput = AVCaptureVideoDataOutput()
    var requests = [VNRequest]()
    var detectionLayer: CALayer! = nil
    var currentFrame = 0
    let framesBetweenRequests = 2 // Change this to set the number of frames between requests

    
    override func viewDidLoad() {
        checkPermission()
        
        sessionQueue.async { [unowned self] in
            guard permissionGranted else { return }
            self.setupCaptureSession()
            
            self.setupLayers()
            self.setupDetector()
            
            self.captureSession.startRunning()
        }
    }
    
    
    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            // Permission has been granted before
            case .authorized:
                permissionGranted = true
                
            // Permission has not been requested yet
            case .notDetermined:
                requestPermission()
                    
            default:
                permissionGranted = false
            }
    }
    
    func requestPermission() {
        sessionQueue.suspend()
        AVCaptureDevice.requestAccess(for: .video) { [unowned self] granted in
            self.permissionGranted = granted
            self.sessionQueue.resume()
        }
    }
    
    func setupCaptureSession() {
        // Camera input
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else { return }
        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else { return }
           
        guard captureSession.canAddInput(videoDeviceInput) else { return }
        captureSession.addInput(videoDeviceInput)
                         
        // Preview layer
        screenRect = UIScreen.main.bounds
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = CGRect(x: 0, y: 0, width: screenRect.size.width, height: screenRect.size.height)
        previewLayer.zPosition = 0
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill // Fill screen
        previewLayer.connection?.videoOrientation = .portrait
        
        // Detector
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sampleBufferQueue"))
        captureSession.addOutput(videoOutput)
        
        videoOutput.connection(with: .video)?.videoOrientation = .portrait
        
        // Updates to UI must be on main queue
        DispatchQueue.main.async { [weak self] in
            self!.view.layer.addSublayer(self!.previewLayer)
        }
    }
    
    func startCaptureSession() {
        sessionQueue.async {
            self.captureSession.startRunning()
        }
    }
    
    func stopCaptureSession() {
        sessionQueue.async {
            self.captureSession.stopRunning()
        }
    }
}


struct HostedObjDetectViewController: UIViewControllerRepresentable {
    // Keep a reference to the ViewController
    var viewController: ObjDetectViewController

    func makeUIViewController(context: Context) -> UIViewController {
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Add/remove the previewLayer as a sublayer to/from the view hierarchy as needed
        if let viewController = uiViewController as?
        ObjDetectViewController{
            if viewController.view.subviews.isEmpty {
                viewController.view.layer.addSublayer(viewController.previewLayer)
            }
        }
    }
}
