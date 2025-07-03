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

public struct CameraMedia {
    public let image: UIImage
    public let metadata: [String: Any]?
    public let timestamp: Date
}
