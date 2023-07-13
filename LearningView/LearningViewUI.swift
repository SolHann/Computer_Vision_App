import SwiftUI
import OrderedCollections
import AVFoundation
/*
 This file is a bunch of structs for the UI elements
 
 The struct 'LearningView' is the UI that is show to the user and uses each of the structus
 */

// This wraps the learning view controller in order that the preview layer can be shown
struct LearningViewRep: UIViewControllerRepresentable {
    typealias UIViewControllerType = LearningViewController

    @ObservedObject var learningVC: LearningViewController

    func makeUIViewController(context: Context) -> LearningViewController {
        return learningVC
    }

    func updateUIViewController(_ uiViewController: LearningViewController, context: Context) {
    }
}

// Button with a counter on
struct CounterButton: View {
    var color: Color
    var colorName: String
    private let size: CGFloat = 64
    
    @Binding var count: Int
    @ObservedObject var learningVC: LearningViewController
    @Binding var flashOpacity: Double
    
    private func addAction(color: String) {
        learningVC.KNN.addDataPoint(features: learningVC.featureArray, label: color)
        count += 1
        
        withAnimation(.easeInOut(duration: 0.1)) {
            flashOpacity = 0.2
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(.easeInOut(duration: 0.1)) {
                flashOpacity = 0
            }
        }
    }
    
    var body: some View {
        VStack {
            Text("\(count) Examples!")
                .foregroundColor(color)
                .font(.system(size: 14))
                .frame(width: 100, height: 20, alignment: .center)
            Button(action: { addAction(color: colorName.lowercased()) }) {
                Text("")
                    .foregroundColor(color)
                    .frame(width: size, height: size)
                    .background(Color.gray.opacity(0.5))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(color, lineWidth: 3))
            }
        }
    }
}


struct DottedUnderline: Shape {
   func path(in rect: CGRect) -> Path {
      var path = Path()
      path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
      path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
      return path
   }
}


struct ConfidenceRectangles: View {
    let color: Color
    let confidence: Double
    
    @Binding var customText: String
    
    private let width: CGFloat = 150
    private let confidenceFontSize = CGFloat(15)
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(color)
                .frame(width: width, height: width / 2.1 )
                .opacity(0.9)
                .cornerRadius(15)
                .shadow(
                    color: (Color.black.opacity(0.4)),
                    radius: 3
                )
            VStack {
                HStack {
                    Image(systemName: "pencil")
                        .foregroundColor(.white)
                    TextField("Enter new text", text: $customText)
                        .padding(.leading, -5)
                        .foregroundColor(.white)
                }
                .overlay(
                    DottedUnderline()
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                        .foregroundColor(.white)
                        .frame(height: 1)
                        .padding(.top, 25)
                )
                Text("Confidence %\(String(format: "%.1f", confidence))")
                    .foregroundColor(.black)
                    .font(.system(size: confidenceFontSize))
            }
            .frame(width: 150)
        }
    }
}

struct RestartButton: View {
    @State private var isExpanded = false
    
    @ObservedObject var learningVC: LearningViewController
    @Binding var redCount: Int
    @Binding var greenCount: Int
    @Binding var blueCount: Int
    
    private let frameSize: CGFloat = 40
    private let iconSize: CGFloat = 25

    var body: some View {
        VStack{
            Button(action: { withAnimation {isExpanded.toggle()}}) {
                Image(systemName: "arrow.clockwise")
                    .scaledToFit()
                    .frame(width: frameSize, height: frameSize)
                    .foregroundColor(.white)
            }
            .background(.gray)
            .clipShape(Circle())
            
            VStack(spacing: isExpanded ? 15:0) {
                Button(action:{
                    learningVC.KNN.removeDataPoints(withLabel: "red");
                    redCount = 0
                }){
                    Image(systemName: "trash.fill")
                        .resizable()
                        .frame(width: isExpanded ? iconSize : 0 ,
                               height: isExpanded ? iconSize : 0)
                        .foregroundColor(.red)
                }.clipShape(Circle())
                
                Button(action:{
                    learningVC.KNN.removeDataPoints(withLabel: "green");
                    greenCount = 0
                }){
                    Image(systemName: "trash.fill")
                        .resizable()
                        .frame(width: isExpanded ? iconSize : 0 ,
                               height: isExpanded ? iconSize : 0)
                        .foregroundColor(.green)
                }.clipShape(Circle())
                
                Button(action: {
                    learningVC.KNN.removeDataPoints(withLabel: "blue");
                    blueCount = 0
                }){
                    Image(systemName: "trash.fill")
                        .resizable()
                        .frame(width: isExpanded ? iconSize : 0 ,
                               height: isExpanded ? iconSize : 0)
                        .foregroundColor(.blue)
                }.clipShape(Circle())
            }
            .padding(.bottom, 15)
        }
        .opacity(0.8)
        .background(isExpanded ? .gray:.clear)
        .cornerRadius(frameSize / 2)
    }
}

struct ButtonItem: Identifiable {
    let id = UUID()
    let label: String
    let action: () -> Void
    let color: Color
}




// Main body
struct LearningView: View {
    @StateObject var learningVC: LearningViewController
    
    @State private var redCounter = 0
    @State private var greenCounter = 0
    @State private var blueCounter = 0
    
    @State private var flashOpacity: Double = 0
    

    var body: some View {
        ZStack {
            LearningViewRep(learningVC: learningVC)  // Camera preview
            GeometryReader { geometry in
                ZStack{  // Prediction at top of screen
                    
                    Rectangle()
                        .fill(learningVC.topPredictionColour)
                        .frame(width: geometry.size.width, height: 150)
                        .position(x: geometry.size.width / 2, y: 25)
                        .opacity(0.9)
                    Text(learningVC.topPrediction)
                        .foregroundColor(.white)
                        .font(.largeTitle)
                        .minimumScaleFactor(0.1)
                        .multilineTextAlignment(.center)
                        .frame(width: geometry.size.width - 50, height: 60)
                        .position(x: geometry.size.width / 2, y: 70)
                        .onChange(of: learningVC.topPrediction) { newValue in
                            learningVC.speakText(learningVC.topPrediction)
                        }
                    VStack{
                        Spacer(minLength: 395)
                        VStack{
                            Button(action: {
                                learningVC.isSpeechEnabled = !learningVC.isSpeechEnabled
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(learningVC.isSpeechEnabled ? Color.gray : Color.red)
                                        .frame(width: 40, height: 40)
                                        .opacity(0.8)
                                    Image(systemName: learningVC.isSpeechEnabled ? "speaker.wave.3.fill" : "speaker.slash.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 25, height: 25)
                                        .foregroundColor(.white)
                                }
                            }
                            RestartButton(learningVC:learningVC, redCount: $redCounter, greenCount: $greenCounter, blueCount: $blueCounter)
                        }
                        Spacer()

                    }
                    .position(x: geometry.size.width - 50, y: 160)
                    
                    VStack {
                        ConfidenceRectangles(color: .red,
                                             confidence:learningVC.prediction["red"] ?? 0.0,
                                             customText:$learningVC.customRedText)
                        ConfidenceRectangles(color: .green,
                                             confidence:learningVC.prediction["green"] ?? 0.0,
                                             customText:$learningVC.customGreenText)
                        ConfidenceRectangles(color: .blue,
                                             confidence:learningVC.prediction["blue"] ?? 0.0,
                                             customText:$learningVC.customBlueText)
                    }
                    .position(x: 110, y: 230)
                }
            }
            
            VStack {
                Spacer()
                HStack(spacing: 30) { // Buttons and counter
                    CounterButton(color: .red, colorName: "Red",
                                  count: $redCounter,
                                  learningVC: learningVC,
                                  flashOpacity: $flashOpacity)
                    CounterButton(color: .green, colorName: "Green",
                                  count: $greenCounter,
                                  learningVC: learningVC,
                                  flashOpacity: $flashOpacity)
                    CounterButton(color: .blue, colorName: "Blue",
                                  count: $blueCounter,
                                  learningVC: learningVC,
                                  flashOpacity: $flashOpacity)
                }
                .padding(.bottom, 100)
            }
            
            GeometryReader { geometry in
                Rectangle()  // Border around screen
                    .stroke(learningVC.topPredictionColour, lineWidth: 40)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .opacity(0.7)
            }
            // Flash effect
            Rectangle()
                .fill(Color.white)
                .opacity(flashOpacity)
                .edgesIgnoringSafeArea(.all)
        }
        .edgesIgnoringSafeArea(.all)
    }
}


struct LearningView_Previews: PreviewProvider {
    static var previews: some View {
        LearningView(learningVC: LearningViewController())
    }
}
