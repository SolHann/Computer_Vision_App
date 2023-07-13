import Vision
import AVFoundation
import SwiftUI

/*
 This is how all the other two viewcontrollers looked before I modularised, It needs to be refactored but I am not sure how to do the bounding boxes with swiftUI.
 */

extension ObjDetectViewController {
    
    func setupDetector() {
        let modelURL = Bundle.main.url(forResource: "YOLOv3TinyInt8LUT", withExtension: "mlmodelc")
        
        do {
            let visionModel = try VNCoreMLModel(for: MLModel(contentsOf: modelURL!))
            let recognitions = VNCoreMLRequest(model: visionModel, completionHandler: detectionDidComplete)
            self.requests = [recognitions]
        } catch let error {
            print(error)
        }
    }
    
    func setupLayers() {
        detectionLayer = CALayer()
        detectionLayer.frame = CGRect(x: 0, y: 0, width: screenRect.size.width, height: screenRect.size.height)
        detectionLayer.zPosition = 1
        self.view.layer.addSublayer(detectionLayer)
    }
    
    // Captures each frame
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        currentFrame += 1
        if currentFrame % framesBetweenRequests == 0 {
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
            do {
                try imageRequestHandler.perform(self.requests)
            } catch {
                print(error)
            }
        }
    }
    
    func detectionDidComplete(request: VNRequest, error: Error?) {
        DispatchQueue.main.async(execute: {
            if let results = request.results {
                self.extractDetections(results)
            }
        })
    }
    
    func extractDetections(_ results: [VNObservation]) {
        detectionLayer.sublayers = nil
        
        for observation in results where observation is VNRecognizedObjectObservation {
            guard let objectObservation = observation as? VNRecognizedObjectObservation else { continue }
            
            // Object Box
            let objectBounds = VNImageRectForNormalizedRect(objectObservation.boundingBox, Int(screenRect.size.width), Int(screenRect.size.height))
            let transformedBounds = CGRect(x: objectBounds.minX, y: screenRect.size.height - objectBounds.maxY, width: objectBounds.maxX - objectBounds.minX, height: objectBounds.maxY - objectBounds.minY)

            // Label / Confidence
            let confidence = objectObservation.confidence
            let objectName = objectObservation.labels[0].identifier
        
            
            let boxLayer = self.drawBoundingBox(transformedBounds)
            detectionLayer.addSublayer(boxLayer)
            let labelLayer = self.drawLabel("\(objectName) (\(Int(confidence * 100))%)", transformedBounds.origin)
            detectionLayer.addSublayer(labelLayer)
        }
    }
    
    func drawLabel(_ text: String, _ origin: CGPoint) -> CALayer {
        let labelLayer = CATextLayer()
        labelLayer.string = text
        labelLayer.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        labelLayer.fontSize = 18
        labelLayer.foregroundColor = UIColor.black.cgColor
        labelLayer.backgroundColor = UIColor.white.cgColor
        labelLayer.cornerRadius = 4
        labelLayer.alignmentMode = .center
        labelLayer.frame = CGRect(x: origin.x, y: origin.y - 25, width: 150, height: 25)
        
        return labelLayer
    }
    
    func drawBoundingBox(_ bounds: CGRect) -> CALayer {
        let boxLayer = CALayer()
        boxLayer.frame = bounds
        boxLayer.borderWidth = 3.0
        boxLayer.borderColor = CGColor.init(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        boxLayer.cornerRadius = 4
        return boxLayer
    }
}
