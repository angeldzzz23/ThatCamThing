//
//  File.swift
//  ThatCamThing
//
//  Created by angel zambrano on 7/2/25.
//

import Foundation
import SwiftUI
import AVKit

public struct CameraPreview: UIViewRepresentable {
    @ObservedObject public var camera: CameraManager
    
    public init(camera: CameraManager) {
        self.camera = camera
    }
    
    public func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        
        camera.preview = AVCaptureVideoPreviewLayer(session: camera.session)
        camera.preview.frame = view.frame
        camera.preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(camera.preview)
        
        camera.startCamera()
        
        return view
    }
    
    public func updateUIView(_ uiView: UIView, context: Context) {}
}
