//
//  File.swift
//  ThatCamThing
//
//  Created by angel zambrano on 7/3/25.
//

import Foundation
import SwiftUI


public protocol CameraOverlay: View {
    var cameraManager: CameraManager { get }
}

