//
//  File.swift
//  ThatCamThing
//
//  Created by angel zambrano on 7/3/25.
//


import SwiftUI


public protocol ErrorOverlay: View {
    init(cameraError: CameraError)
}
