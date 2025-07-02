//
//  File.swift
//  ThatCamThing
//
//  Created by angel zambrano on 7/1/25.
//

import Foundation

extension CameraManager: CameraConfigurationManaging {
    func updateCameraPosition(_ position: CameraPosition) {
        attributes.cameraPosition = position
    }
    
    func updateResolution(_ resolution: AVCaptureSession.Preset) {
        attributes.resolution = resolution
    }
    
    func updateZoomFactor(_ zoom: CGFloat) {
        attributes.zoomFactor = zoom
    }
    
    func updateFlashMode(_ flashMode: CameraFlashMode) {
        attributes.flashMode = flashMode
    }
    
    func updateMirrorOutput(_ mirror: Bool) {
        attributes.mirrorOutput = mirror
    }
    
    func updateFrameRate(_ frameRate: Int32) {
        attributes.frameRate = frameRate
    }
}
