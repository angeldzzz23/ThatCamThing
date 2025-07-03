//
//  File.swift
//  ThatCamThing
//
//  Created by angel zambrano on 7/3/25.
//

import SwiftUI

public protocol CameraOverlay: View {
    init(camera: CameraManager)
}

//MARK: Creates an EmptyCameraOverlay
public struct EmptyCameraOverlay: CameraOverlay {
    public init(camera: CameraManager) {
        // Empty initializer - we don't need to store the camera manager
    }
    
    public var body: some View {
        EmptyView()
    }
}
