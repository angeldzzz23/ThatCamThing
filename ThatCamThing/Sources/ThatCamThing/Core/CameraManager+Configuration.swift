//
//  File.swift
//  ThatCamThing
//
//  Created by angel zambrano on 7/1/25.
//

import Foundation

extension CameraManager: CameraConfigurationManaging {
    public func updateCameraPosition(_ position: CameraPosition) {
        attributes.cameraPosition = position
    }
    
    public func updateResolution(_ resolution: AVCaptureSession.Preset) {
        attributes.resolution = resolution
    }
    
    public  func updateZoomFactor(_ zoom: CGFloat) {
        attributes.zoomFactor = zoom
    }
    
    public func updateFlashMode(_ flashMode: CameraFlashMode) {
        attributes.flashMode = flashMode
    }
    
    public func updateMirrorOutput(_ mirror: Bool) {
        attributes.mirrorOutput = mirror
    }
    
    public func updateFrameRate(_ frameRate: Int32) {
        attributes.frameRate = frameRate
    }
}
