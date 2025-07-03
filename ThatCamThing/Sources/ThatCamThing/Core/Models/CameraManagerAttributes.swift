//
//  CameraError.swift
//  ThatCamThing
//
//  Created by angel zambrano on 7/2/25.
//


import Foundation
import SwiftUI
import PhotosUI
import AVFoundation
import AVKit


public enum CameraOutputType: CaseIterable {
    case photo
}

public enum CameraPosition: CaseIterable, Sendable {
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

public enum CameraLensType: CaseIterable, Sendable {
    case wide
    case ultraWide
    
    public var deviceType: AVCaptureDevice.DeviceType {
        switch self {
        case .wide:
            return .builtInWideAngleCamera
        case .ultraWide:
            return .builtInUltraWideCamera
        }
    }
    
    public var displayName: String {
        switch self {
        case .wide:
            return "Wide"
        case .ultraWide:
            return "Ultra Wide"
        }
    }
}

public struct CameraMedia {
    public let image: UIImage
    public let metadata: [String: Any]?
    public let timestamp: Date
}

// TODO: remove errors from here and capture media
public struct CameraManagerAttributes {
    public var capturedMedia: CameraMedia?
    public var outputType = CameraOutputType.photo
    public var cameraPosition = CameraPosition.back
    public var zoomFactor: CGFloat = 1.0
    public var frameRate: Int32 = 30
    public var flashMode = CameraFlashMode.off
    public var resolution = AVCaptureSession.Preset.hd1920x1080
    public var mirrorOutput = false
    public var lensType = CameraLensType.wide
    public var isPaused = false
    public var isUltraWideLensAvailable = false
}
