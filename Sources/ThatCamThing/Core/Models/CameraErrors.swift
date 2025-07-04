//
//  File.swift
//  ThatCamThing
//
//  Created by angel zambrano on 7/3/25.
//
import Foundation
import SwiftUI
import PhotosUI
import AVFoundation
import AVKit

// MARK: - Core Models and Enums

public enum CameraError: Error {
    case cameraPermissionsNotGranted
    case cannotSetupInput, cannotSetupOutput
}
