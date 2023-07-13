import Vision

class MobileNetClassifier: ObservableObject {
    
    @Published var predictedLabel = "Unknown"
    
    private let mlModel = "MobileNetV2Int8LUT"
    private var requests = [VNRequest]()
    
    func setupClassifier(){
        let modelURL = Bundle.main.url(forResource: mlModel, withExtension: "mlmodelc")
        do {
            let visionModel = try VNCoreMLModel(for: MLModel(contentsOf: modelURL!))
            let recognitions = VNCoreMLRequest(model: visionModel, completionHandler: extractPrediction)
            self.requests = [recognitions]
        } catch let error {
            print(error)
        }
    }
    
    
    // Take an image in the form of a sample buffle, format it then do detection called once every x frames by classifierViewController
    func processSampleBuffer(_ sampleBuffer: CMSampleBuffer){
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        do {
            try imageRequestHandler.perform(self.requests) // See setup and extractPrediction
        } catch {
            print(error)
        }
    }
    
    // Called automatically according to setupDetector as the completion handler for the model
    func extractPrediction(request: VNRequest, error: Error?) {
        DispatchQueue.main.async(execute: {
            if let results = request.results as? [VNClassificationObservation] {
                let sortedResults = results.sorted(by: { $0.confidence > $1.confidence })
                if let topPrediction = sortedResults.first {
                    if topPrediction.confidence > 0.2 {
                        self.predictedLabel = topPrediction.identifier
                    } else {
                        self.predictedLabel = "Unsure"
                    }
                }
              }
        })
    }

}
