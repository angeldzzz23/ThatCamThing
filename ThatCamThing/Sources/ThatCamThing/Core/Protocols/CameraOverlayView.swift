//
//  CameraOverlayView.swift
//  ThatCamThing
//
//  Created by angel zambrano on 7/1/25.
//


public protocol CameraOverlayView: View {
    associatedtype Control: CameraControl
    var cameraControl: Control { get }
    
    init(cameraControl: Control)
}

