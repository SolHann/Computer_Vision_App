import SwiftUI
import AVFoundation
import Vision
import OrderedCollections

class LearningViewController: UIViewController, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    let KNN = KNNClassifier()
    let cameraCapture = CameraCapture()
    let predictor = LearntPredictor()
    let synthesizer = AVSpeechSynthesizer()
    
    @Published var isSpeechEnabled = true
    @Published var topPrediction = "Take pictures to train your own model!"
    @Published var topPredictionColour: Color = .black
    @Published var prediction: OrderedDictionary<String, Double> = [
        "red": 0.0,
        "green": 0.0,
        "blue": 0.0
    ]
    @Published var customRedText = "Tap to change"
    @Published var customGreenText = "Awesome"
    @Published var customBlueText = "Hello"
    
    var featureArray: [Double] = []
    private var currentFrame = 0
    private let framesBetweenRequests = 5
    private var permissionGranted = false
    private var previewLayer: AVCaptureVideoPreviewLayer {
        return cameraCapture.previewLayer
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        cameraCapture.delegate = self
        checkPermission()
        guard permissionGranted else { return }

        cameraCapture.setupCaptureSession()
        cameraCapture.sessionQueue.async {
            self.cameraCapture.captureSession.startRunning()
        }
        view.layer.addSublayer(previewLayer)
    }

    // This is called every frame
    func captureOutput(_ _: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from _: AVCaptureConnection) {
        currentFrame += 1

        if currentFrame % framesBetweenRequests == 0 { // Do prediction every x frames
            DispatchQueue.main.async { [self] in
                // Feature array is a representation of the image, KNN then predicts which label it is most similar to
                featureArray = predictor.getFeatureArray(sampleBuffer)
                prediction = KNN.predict(features: featureArray) ?? ["": 0.0]
                
                switch prediction.elements[0].key {
                case "red":
                    topPrediction = customRedText
                case "green":
                    topPrediction = customGreenText
                case "blue":
                    topPrediction = customBlueText
                default:
                    topPrediction = "Take photos to create your own model!"
                }
                
                topPredictionColour = Color(getColor(from: prediction.elements[0].key))
            }
        }
    }


    // Helper function for creating border colour
    private func getColor(from string: String) -> UIColor {
            switch string.lowercased() {
            case "red":
                return UIColor.red
            case "green":
                return UIColor.green
            case "blue":
                return UIColor.blue
            default:
                return UIColor.purple
            }
        }
    
    func speakText(_ text: String) {
        if isSpeechEnabled {
            synthesizer.stopSpeaking(at: .immediate) // Stop previous speech immediately
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
            utterance.rate = 0.5
            synthesizer.speak(utterance)
        }
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

