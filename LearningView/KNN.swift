import Foundation
import OrderedCollections
/*
 A KNNClassifier that outputs a dictionaries of labels : confidence sorted by confidence
 
 */
struct DataPoint {
    let features: [Double]
    let label: String
}

class KNNClassifier {
    private(set) var dataPoints: [DataPoint] = []
    private let k = 3
    private var allLabels = ["red", "green", "blue"]
    
    func addDataPoint(features: [Double], label: String) {
        dataPoints.append(DataPoint(features: features, label: label))
    }
    
    func removeDataPoints(withLabel label: String) {
        dataPoints.removeAll { $0.label == label }
    }
    
    func predict(features: [Double]) -> OrderedDictionary<String, Double>? {
        guard !dataPoints.isEmpty else { return nil }
        
        // For every datapoint find the distance between every feature and the new feature array,
        // return a list of the summed distances for each datapoint
        let distances = dataPoints.map { dataPoint -> (label: String, distance: Double) in
            let distance = zip(dataPoint.features, features).map { pow($0.0 - $0.1, 2) }.reduce(0, +)
            return (label: dataPoint.label, distance: distance)
        }
        // Get k nearest neighbours
        let nearestNeighbors = distances.sorted { $0.distance < $1.distance }.prefix(k)
        
        // Calculate the weights of each label based on the inverse of the distances
        let labelWeights = nearestNeighbors.reduce(into: [String: Double]()) { (result, neighbor) in
            let weight = neighbor.distance == 0 ? Double.greatestFiniteMagnitude : 1 / neighbor.distance
            result[neighbor.label, default: 0] += weight
        }
        // Calculate confidences
        let totalWeight = labelWeights.values.reduce(0, +)
        var confidences: OrderedDictionary<String, Double> = allLabels.reduce(into: [:]) { $0[$1] = 0 }
        labelWeights.forEach { (label, weight) in
            confidences[label] = weight / totalWeight * 100
        }

        let sortedOrderedConfidences = confidences.sorted { $0.value > $1.value }.reduce(into: OrderedDictionary<String, Double>()) { (result, keyValue) in
            result[keyValue.key] = keyValue.value
        }

        return sortedOrderedConfidences
    }
}
