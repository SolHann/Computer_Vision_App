import AVFoundation
import SwiftUI


// The `CameraCapture` class is designed to manage a camera capture session using AVFoundation. It sets up a capture session with the device's back camera and provides a preview layer that can be added to a view to display the camera feed.
class CameraCapture{
    private var videoOutput = AVCaptureVideoDataOutput()
    private var screenRect: CGRect! = nil // For view dimension
    
    var previewLayer = AVCaptureVideoPreviewLayer()
    let sessionQueue = DispatchQueue(label: "sessionQueue")
    let captureSession = AVCaptureSession()
    
    // This delegate will be notified whenever a new video frame is captured, allowing for real-time processing of the video feed.
    weak var delegate: AVCaptureVideoDataOutputSampleBufferDelegate?

    // Helper function to get the widest available camera
    func selectWideCamera() -> AVCaptureDevice? {
        let cameraTypes: [AVCaptureDevice.DeviceType] = [
            .builtInUltraWideCamera,
            .builtInDualWideCamera,
            .builtInWideAngleCamera
        ]
        
        for cameraType in cameraTypes {
            if let device = AVCaptureDevice.default(cameraType, for: .video, position: .back) {
                return device
            }
        }
        
        return nil
    }
    
    func setupCaptureSession() {
        // Camera input
        guard let videoDevice = selectWideCamera(), let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else { return }
        
        guard captureSession.canAddInput(videoDeviceInput) else { return }
        captureSession.addInput(videoDeviceInput)
        
        // Preview layer
        screenRect = UIScreen.main.bounds
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = CGRect(x: 0, y: 0, width: screenRect.size.width, height: screenRect.size.height)
        previewLayer.zPosition = 0
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill // Fill screen
        previewLayer.connection?.videoOrientation = .portrait
        
        // For the Detector
        videoOutput.setSampleBufferDelegate(delegate, queue: DispatchQueue(label: "sampleBufferQueue"))
        captureSession.addOutput(videoOutput)
        
        videoOutput.connection(with: .video)?.videoOrientation = .portrait
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


