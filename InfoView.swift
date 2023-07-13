import SwiftUI
import Foundation


struct FAQ {
    var question: String
    var answer: String
}

struct InfoView: View {
    @State var expandedIndex: Int? = 0
    var faqs: [FAQ] = [
        FAQ(question: "How to use the app?", answer: "The app has three main modes that you can access using the tab bar at the bottom of the screen: Object Detection, Classification, and Learning. In Object Detection and Classification modes, you can explore pre-built models that have been trained on a neural network using over a million images.\n\nLearning mode allows you to create your own custom model by taking photos with the Red, Green, and Blue buttons at the bottom of the screen. When you take a photo of an object, you train that colour's classifier. By taking multiple photos of the object in various contexts, the classifier will be able to recognise the object more accurately."),
        FAQ(question: "How does the classifier work?", answer: "A classifier in computer vision is a type of machine learning algorithm that helps computers identify and categorise objects within images. It works by learning patterns and features from a set of labelled examples (images with corresponding labels) during a training process. The classifier then uses this knowledge to determine the category of new, unseen images.\n\nIn essence, the classifier learns to recognise objects by analysing the visual features of the images, such as shapes, colours, and textures. It then creates a mathematical model that can distinguish between different categories based on these features. When presented with a new image, the classifier uses the model to analyse its features and predicts which category it belongs to. This allows the classifier to automatically recognise and categorise objects in images, making it a valuable tool in various computer vision applications."),
        FAQ(question: "How does learning mode work?", answer: "The learning mode utilises a pre-built classifier with the last layer removed. The output from this modified classifier is then input into a K-Nearest Neighbours (KNN) algorithm, which identifies the most similar colour based on the training data you have provided. Each frame captured by the camera passes through this model, just like in the classifier and object detection modes. When you press one of the three buttons, an example is added to the KNN algorithm. As you move your camera around, the app tries to determine which set of images the current view is most similar to."),
        FAQ(question: "Who made this app?", answer: "The concept of the learning mode was inspired by Google's 'Teachable Machine'. The implementation was primarily based on the teachable-machine-v1 project on GitHub, with significant contributions from Lasse Korsgaard and Jonas Jongejan. However, the original web app was not well optimised for mobile devices.\n\nAs a result, I (Sol Hann) developed an iPhone app using Swift for my BSc dissertation. The idea to create the app came from my supervisor Sebastian Wild, who wanted to use it for student outreach. Keeping this purpose in mind, I expanded the app to include demos of various types of computer vision models."),
    ]
    
    var body: some View {
        ZStack {
            Color.white
                .edgesIgnoringSafeArea(.all)
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(faqs.indices, id: \.self) { index in
                        BubbleView(question: faqs[index].question, answer: faqs[index].answer, isExpanded: Binding(
                            get: {
                                index == expandedIndex
                            },
                            set: { newValue in
                                withAnimation {
                                    expandedIndex = newValue ? index : nil
                                }
                            }
                        ))
                        .id(index)
                    }
                }
            }
        }
    }
}

struct BubbleView: View {
    var question: String
    var answer: String
    @Binding var isExpanded: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(question)
                .font(.headline)
                .multilineTextAlignment(.leading)
                .bold()
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
            if isExpanded {
                Text(answer)
                    .padding()
                    .background(Color.white)
                    .foregroundColor(.black)
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(isExpanded ? Color.blue : Color.gray)
        .cornerRadius(20)
        .onTapGesture {
            isExpanded.toggle()
        }
    }
}
