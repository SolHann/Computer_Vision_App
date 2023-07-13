import Foundation
import SwiftUI


struct MainView: View {
    private var classifierVC = ClassifierViewController()
    private var learningVC = LearningViewController()
    
    var body: some View {
        
        TabView {
            LearningView(learningVC: learningVC)
                .tabItem {
                    Label("Learning", systemImage: "camera.metering.unknown")
                }
                .onAppear {
                    learningVC.cameraCapture.startCaptureSession()
                }
                .onDisappear {
                    learningVC.cameraCapture.stopCaptureSession()
                }
            
            ClassifierView(classifierVC: classifierVC)
                .tabItem {
                    Label("Classification", systemImage: "camera.viewfinder")
                }
                .onAppear {
                    classifierVC.cameraCapture.startCaptureSession()
                }
                .onDisappear {
                    classifierVC.cameraCapture.stopCaptureSession()
                }
            
            ObjectDetectView()
                .tabItem {
                    Label("Object Detection", systemImage: "camera.metering.center.weighted")
                }
            
            
            InfoView()
                .tabItem {
                    Label("Information", systemImage: "info.bubble")
                }
        }
        .onAppear {
            UITabBar.appearance().barTintColor = UIColor.white.withAlphaComponent(0.8)
        }
        
    }
}


struct ObjectDetectView: View {
    var body: some View {
        let viewController = ObjDetectViewController()
        return HostedObjDetectViewController(viewController: viewController)
            .onDisappear {
                viewController.stopCaptureSession()
            }
            .onAppear {
                viewController.startCaptureSession()
            }
            .ignoresSafeArea() 
    }
}



