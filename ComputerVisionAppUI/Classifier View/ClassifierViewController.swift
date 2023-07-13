import SwiftUI
import AVFoundation
import Vision


class ClassifierViewController: UIViewController, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let cameraCapture = CameraCapture()
    var predictor = MobileNetClassifier()
    
    @Published var predictedLabel = "Unknown"
    @Published var currentColor: Color = .red
    
    var permissionGranted = false
    var previewLayer: AVCaptureVideoPreviewLayer {
        return cameraCapture.previewLayer
    }
    private var currentFrame = 0
    private let framesBetweenRequests = 5
     
//  Potentially could delete this and replace with init() methods in the predictor and cameraCapture, permission would still need to be granted but maybe this could be done earlier when you first open the app ever. However eithier this or the 'cameraCapture' needs to be a view controller anyway since using a UI reprentable is the only way to show AV caputre sessionin swiftUI
    override func viewDidLoad() {
        super.viewDidLoad()
        cameraCapture.delegate = self
        checkPermission()
        guard permissionGranted else { return }

        cameraCapture.setupCaptureSession()
        cameraCapture.sessionQueue.async {
            self.cameraCapture.captureSession.startRunning()
        }
        predictor.setupClassifier()
        view.layer.addSublayer(previewLayer)
    }
    
    // As the delegate for cameraCapture this gets every frame in order to do computer vision processing
    func captureOutput(_ _: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from _: AVCaptureConnection) {
        currentFrame += 1
        if currentFrame % framesBetweenRequests == 0 { // Do prediction every x frames
            predictor.processSampleBuffer(sampleBuffer)
            DispatchQueue.main.async {
                self.predictedLabel = self.predictor.predictedLabel
                self.currentColor = Color(self.getColour(str: self.predictor.predictedLabel))
            }
        }
    }
    
    // Gets pseudo random colour using hashvalues of the first three letters of classification result
    private func getColour(str: String) -> UIColor {
        let chars = Array(str.prefix(3))
        let maxBrightness = 190  // Set to 256 for full range of colours but darker makes font stand out better
        let red = Double(abs(chars[0].hashValue % maxBrightness))
        let green = Double(abs(chars[1].hashValue % maxBrightness))
        let blue = Double(abs(chars[2].hashValue % maxBrightness))
        
        return UIColor(red: red / 256, green: green / 256, blue: blue / 256, alpha: 1)
    }
    
    private func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            // Permission has been granted before
            case .authorized:
                permissionGranted = true
                
            case .notDetermined:
                requestPermission()
                    
            default:
                permissionGranted = false
            }
    }
    
    private func requestPermission() {
        cameraCapture.sessionQueue.suspend()
        AVCaptureDevice.requestAccess(for: .video) { [unowned self] granted in
            self.permissionGranted = granted
            cameraCapture.sessionQueue.resume()
        }
    }
}

// This wraps the calssifier view controller in something that swiftUI likes, imo its ugly but neccessary
struct ClassifierRep: UIViewControllerRepresentable {
    typealias UIViewControllerType = ClassifierViewController
    @ObservedObject var classifierVC: ClassifierViewController
    
    func makeUIViewController(context: Context) -> ClassifierViewController {return classifierVC}
    func updateUIViewController(_ uiViewController: ClassifierViewController, context: Context) {}
}

//ui
struct ClassifierView: View {
    @StateObject var classifierVC: ClassifierViewController
    
    let frame_width: CGFloat = 40
    let rectangle_size: CGFloat = 150
    var body: some View {
        ZStack {
            ClassifierRep(classifierVC: classifierVC)
            
            GeometryReader { geometry in
                ZStack{
                    Rectangle()
                        .fill(classifierVC.currentColor)
                        .frame(width: geometry.size.width, height: rectangle_size)
                        .position(x: geometry.size.width / 2, y: 25)
                        .opacity(0.9)
                }
                Text(classifierVC.predictedLabel)
                    .foregroundColor(.white)
                    .font(.system(size: 35))
                    .position(x: geometry.size.width / 2, y: 70)

            }
            
            GeometryReader { geometry in
                Rectangle()
                    .stroke(classifierVC.currentColor, lineWidth: frame_width) //
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .opacity(0.7)
            
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}
