//
//  VideoPreviewView.swift
//  ThatCamThing
//
//  Created by angel zambrano on 7/1/25.
//


import Foundation
import AVKit
import SwiftUI
import Photos


public class VideoPreviewView: UIView {
    var session: AVCaptureSession? {
        didSet {
            guard let session = session else { return }
            videoPreviewLayer.session = session
        }
    }
    
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        videoPreviewLayer.videoGravity = .resizeAspectFill
    }
}
