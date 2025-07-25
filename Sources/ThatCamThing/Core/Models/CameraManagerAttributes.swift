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

public enum FrameRate {
    case fps15
    case fps24
    case fps30
    case fps60
    case fps120

   public var asInt32: Int32 {
        switch self {
        case .fps15: return 15
        case .fps24: return 24
        case .fps30: return 30
        case .fps60: return 60
        case .fps120: return 120
        }
    }
}

public struct CameraManagerAttributes {
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
    
    public init(
        outputType: CameraOutputType = .photo,
        cameraPosition: CameraPosition = .back,
        zoomFactor: CGFloat = 1.0,
        frameRate: FrameRate = .fps30,
        flashMode: CameraFlashMode = .off,
        resolution: AVCaptureSession.Preset = .hd1920x1080,
        mirrorOutput: Bool = false,
        lensType: CameraLensType = .wide,
        isPaused: Bool = false,
        isUltraWideLensAvailable: Bool = false
    ) {
        self.outputType = outputType
        self.cameraPosition = cameraPosition
        self.zoomFactor = zoomFactor
        self.frameRate = frameRate.asInt32
        self.flashMode = flashMode
        self.resolution = resolution
        self.mirrorOutput = mirrorOutput
        self.lensType = lensType
        self.isPaused = isPaused
        self.isUltraWideLensAvailable = isUltraWideLensAvailable
    }
}
