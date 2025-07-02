//
//  CameraError.swift
//  ThatCamThing
//
//  Created by angel zambrano on 7/1/25.
//


import Foundation
import AVKit

// MARK: - Core Models and Enums

public enum CameraError: Error {
    case cameraPermissionsNotGranted
    case cannotSetupInput, cannotSetupOutput
}

public enum CameraOutputType: CaseIterable {
    case photo
}

public enum CameraPosition: CaseIterable {
    case back
    case front
}

public enum CameraFlashMode: CaseIterable {
    case off
    case on
    case auto
}

public enum CameraHDRMode: CaseIterable {
    case off
    case on
    case auto
}

public struct CameraMedia {
    public let image: UIImage
    public let metadata: [String: Any]?
    public  let timestamp: Date
}

public struct CameraManagerAttributes {
     public var capturedMedia: CameraMedia?
    public var error: CameraError?
    public var outputType = CameraOutputType.photo
    public  var cameraPosition = CameraPosition.back
    public  var zoomFactor: CGFloat = 1.0
    public  var frameRate: Int32 = 30
    public  var flashMode = CameraFlashMode.off
    public var resolution = AVCaptureSession.Preset.hd1920x1080
    public   var mirrorOutput = false
    
    
// TODO: 
//    var orientationLocked = false
//    var userBlockedScreenRotation = false
//    var frameOrientation = CGImagePropertyOrientation.up
//    var hdrMode: CameraHDRMode = .auto
//    var deviceOrientation: AVCaptureVideoOrientation = .portrait
//    var frameOrientation: CGImagePropertyOrientation = .right

}

