//
//  File.swift
//  ThatCamThing
//
//  Created by angel zambrano on 7/3/25.
//

import Foundation
import SwiftUI
import ThatCamThing

public protocol CameraOverlay: View {
    var camera: CameraManager { get }
}

